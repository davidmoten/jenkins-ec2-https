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

```bash
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install jenkins
```

