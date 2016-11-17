# jenkins-ec2-https
How to setup Jenkins CI on EC2 (Ubuntu 16.04 LTS) with https access.

This task took me three hours reading a lot of web pages and lots of trial and error. To make your life easier this is what you need to do to setup a Jenkins CI instance using your AWS account.

##Create an EC2 instance
* open AWS Console in browser
* go to EC2
* Launch Instance - select Ubuntu 16.04 server image
* Security group - allow inbound on SSH 22 and HTTPS 443
* 8gb is fine for small Jenkins builds (I went for 100GB to handle our enterprise builds)
* In EC2 go to instances, once instance running then select Connect
* copy ssh command to terminal and connect

Sources:
* https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Ubuntu
* https://github.com/hughperkins/howto-jenkins-ssl
* https://wiki.jenkins-ci.org/display/JENKINS/Running+Jenkins+behind+Apache

```bash
sudo apt-get update
sudo apt-get upgrade

wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins

sudo apt-get install apache2
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod headers

sudo mv /etc/apache2/sites-enabled/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf.bak

# configure apache for ssl proxying
sudo cat <<EOF >/etc/apache2/sites-enabled/ssl.conf
LoadModule ssl_module modules/mod_ssl.so
LoadModule proxy_module modules/mod_proxy.so
Listen 443
<VirtualHost *:443>
  <Proxy "*">
    Order deny,allow
    Allow from all
  </Proxy>
  
  SSLEngine             on
  SSLCertificateFile	/etc/ssl/certs/ssl-cert-snakeoil.pem
  SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
  
  # this option is mandatory to force apache to forward the client cert data to tomcat
  SSLOptions +ExportCertData
  
  Header always set Strict-Transport-Security "max-age=63072000; includeSubdomains; preload"
  Header always set X-Frame-Options DENY
  Header always set X-Content-Type-Options nosniff
  
  ProxyPass / http://localhost:8080/ retry=0
  ProxyPassReverse / http://localhost:8080/
  ProxyPreserveHost on
  
  LogFormat "%h (%{X-Forwarded-For}i) %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\""
  ErrorLog /var/log/apache2/ssl-error_log
  TransferLog /var/log/apache2/ssl-access_log
</VirtualHost>
EOF

## restart apache
sudo service apache2 restart

## print out jenkins password for initial admin login
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
The script above uses the default ssl certificates for apache2 (and these will work but in the browser you will be warned about the certificates being insecure). To make a self-signed certificate that at least matches the desired host name do the following:

```bash
cd ~
# we are now in /home/ubuntu

#set this password for your needs
CA_PASSWORD=blahblah

# create server certificates (public and private)
tee server-config <<EOF
# OpenSSL configuration file.
[ req ]
prompt = no
distinguished_name			= req_distinguished_name
 
[ req_distinguished_name ]
C=AU
ST=Australian Capital Territory
L=Canberra
CN=ec2-52-63-123-456.ap-southeast-2.compute.amazonaws.com
O=Some Company
OU=Some Division
emailAddress=myemail@gmail.com
EOF

openssl genrsa -out key.pem  2048 # creates key.pem
openssl req -sha256 -new -key key.pem -out csr.pem -config server-config
openssl x509 -req -days 9999 -in csr.pem -signkey key.pem -out cert.pem -passin "pass:$CA_PASSWORD"
rm csr.pem
rm server-config

sudo cp cert.pem /etc/ssl/certs/my-cert.pem
sudo cp key.pem /etc/ssl/private/my-key.pem
```

Now edit the location of the keys in `/etc/apache2/sites-enabled/ssl.conf` so that those lines look like:

```
  SSLCertificateFile	/etc/ssl/certs/my-cert.pem
  SSLCertificateKeyFile /etc/ssl/private/my-key.pem
```
Restart apache2:
```bash
sudo service apache2 restart
```
