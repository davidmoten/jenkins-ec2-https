# jenkins-ec2-https
How to setup Jenkins CI on EC2 (Ubuntu 16.04 LTS) with https access.

This task took me three hours reading a lot of web pages and lots of trial and error. To make your life easier this is what you need to do to setup a Jenkins CI instance using your AWS account.

##Create an EC2 instance
* open AWS Console in browser
* go to EC2
* select **Launch Instance** - select **Ubuntu Server 16.04 LTS**
* select **t2.micro**
* select **Configure Instance Details**
* tick **Enable termination protection**
* select **Add Storage**
* change size to preferred (I use 100GB for our large enterprise builds)
* select **Add Tags**
* set value to *Jenkins*
* select *Configure Security Group*
* add rule *HTTPS*
* select **Review and launch**
* select a key pair
* select **Launch Instance**

* In EC2 go to instances, once instance running then select instance and click Connect
* copy ssh command to terminal and connect

Sources:
* https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Ubuntu
* https://github.com/hughperkins/howto-jenkins-ssl
* https://wiki.jenkins-ci.org/display/JENKINS/Running+Jenkins+behind+Apache

```bash
#!/bin/bash
set -e 
set -x

sudo apt-get update
sudo apt-get upgrade -y

wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins -y

sudo apt-get install apache2 -y
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod headers

# configure apache for ssl proxying
sudo tee /etc/apache2/sites-enabled/ssl.conf <<EOF
LoadModule ssl_module modules/mod_ssl.so
LoadModule proxy_module modules/mod_proxy.so
Listen 443
<VirtualHost *:443>
  <Proxy "*">
    Order deny,allow
    Allow from all
  </Proxy>
  
  SSLEngine             on
  SSLCertificateFile	/etc/ssl/certs/my-cert.pem
  SSLCertificateKeyFile /etc/ssl/private/my-key.pem
  
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

## print out jenkins password for initial admin login
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

## The script above uses the default ssl certificates for apache2
## (and these will work but in the browser you will be warned about
## the certificates being insecure). To make a self-signed certificate
## that at least matches the desired host name:

tee create-certs.sh <<ZZZZ
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

sudo service apache2 restart
ZZZZ

chmod +x create-certs.sh
set +x
echo '****************************************'
echo '* Now you should edit create-certs.sh '
echo '* to update the CA_PASSWORD and your   '
echo '* certificate fields...'
echo '****************************************'
```
Now edit create-certs.sh and update the CA_PASSWORD and certificate fields (especially the CN field which is the hostname). Then run the create-certs.sh script:
```bash
./create-certs.sh
```
