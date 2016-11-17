# jenkins-ec2-https
How to setup Jenkins CI on EC2 with https access.

This task took me three hours reading a lot of web pages and lots of trial and error. So I don't forget and to make your life easier this is what you need to do to setup a Jenkins CI instance using your AWS account.

##Create an EC2 instance
* open AWS Console in browser
* go to EC2
* Launch Instance - select Ubuntu 16.04 server image
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
```

