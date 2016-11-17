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
sudo a2enmod ssl

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
  SSLCertificateFile    /etc/ssl/certs/my-cert.pem
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
distinguished_name          = req_distinguished_name

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
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
ZZZZ

chmod +x create-certs.sh
set +x
echo '****************************************'
echo '* Now you should edit create-certs.sh '
echo '* to update the CA_PASSWORD and your   '
echo '* certificate fields. Then run '
echo '    ./create-certs.sh '
echo '* the last line of output from that script'
echo '* is the password to be entered first time '
echo '* you go to the jenkins url in browser'
echo '****************************************'