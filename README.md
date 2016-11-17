# jenkins-ec2-https
How to setup Jenkins CI on EC2 with https access.

This task took me three hours reading a lot of web pages and lots of trial and error. So I don't forget and to make your life easier this is what you need to do to setup a Jenkins CI instance using your AWS account.

##Create an EC2 instance
* open AWS Console in browser
* go to EC2
* Launch Instance - select Ubuntu 16.04 server image
* Security group - allow inbound on SSH 22 and HTTPS 443
* 8gb is fine for OS, add EBS volume if you need it (I used 100GB)
* In EC2 go to instances, once instance running then select Connect
* copy ssh command to terminal and connect

from https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Ubuntu
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
sudo cat <<EOT >/etc/apache2/sites-enabled/ssl.conf
LoadModule ssl_module modules/mod_ssl.so
LoadModule proxy_module modules/mod_proxy.so
#SSLVerifyClient require
#SSLVerifyDepth 1
#SSLCACertificateFile "/etc/pki/tls/certs/ca.crt"
Listen 443
<VirtualHost *:443>
  <Proxy "*">
    Order deny,allow
    Allow from all
  </Proxy>
  
  SSLEngine             on
  SSLCertificateFile	/etc/ssl/certs/ssl-cert-snakeoil.pem
  SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
  #SSLCipherSuite        EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH
  #SSLProtocol           All -SSLv2 -SSLv3
  #SSLHonorCipherOrder   On
  
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
EOT

## restart apache
sudo service apache2 restart

## print out jenkins password for initial admin login
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

