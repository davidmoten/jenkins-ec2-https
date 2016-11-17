#!/bin/bash
#################################################################
## Set the values in this section
#################################################################
HOSTNAME='ec2-52-63-456-123.ap-southeast-2.compute.amazonaws.com'
COUNTRY='AU'
STATE='Australian Capital Territory'
CITY='Canberra'
COMPANY='MyCompany'
DIVISON='IT'
EMAIL='somebody@gmail.com'
#################################################################

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

  ProxyPass / http://localhost:8080/ retry=0 nocanon
  ProxyPassReverse / http://localhost:8080/
  ProxyPreserveHost on
  AllowEncodedSlashes NoDecode
  RequestHeader set X-Forwarded-Proto "https"
  RequestHeader set X-Forwarded-Port "443"

  LogFormat "%h (%{X-Forwarded-For}i) %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\""
  ErrorLog /var/log/apache2/ssl-error_log
  TransferLog /var/log/apache2/ssl-access_log
</VirtualHost>
EOF

## print out jenkins password for initial admin login
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

## The script above uses the default ssl certificates for apache2
## (and these will work but in the browser you will be warned about
## the certificates being insecure). Now we make a self-signed certificate
## that at least matches the desired host name:

cd ~
# we are now in /home/ubuntu

#generate a password
CA_PASSWORD=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32}`

# create server certificates (public and p`)
tee server-config <<EOF
# OpenSSL configuration file.
[ req ]
prompt = no
distinguished_name          = req_distinguished_name

[ req_distinguished_name ]
C=TheCountry
ST=TheState
L=TheCity
CN=TheHostname
O=TheCompany
OU=TheDivision
emailAddress=TheEmail
EOF
sed -i -e "s/TheCountry/$COUNTRY/g" server-config
sed -i -e "s/TheState/$STATE/g" server-config
sed -i -e "s/TheCity/$CITY/g" server-config
sed -i -e "s/TheHostname/$HOSTNAME/g" server-config
sed -i -e "s/TheCompany/$COMPANY/g" server-config
sed -i -e "s/TheDivision/$DIVISION/g" server-config
sed -i -e "s/TheEmail/$EMAIL/g" server-config

openssl genrsa -out key.pem  2048 # creates key.pem
openssl req -sha256 -new -key key.pem -out csr.pem -config server-config
openssl x509 -req -days 9999 -in csr.pem -signkey key.pem -out cert.pem -passin "pass:$CA_PASSWORD"
rm csr.pem
rm server-config

sudo cp cert.pem /etc/ssl/certs/my-cert.pem
sudo cp key.pem /etc/ssl/private/my-key.pem

sudo service apache2 restart
set +x
echo CA password (you probably don't need it):
echo $CA_PASSWORD
echo initial administration password to enter into browser:
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
