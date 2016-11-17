# jenkins-ec2-https
How to setup [Jenkins CI](https://jenkins.io/) on EC2 (Ubuntu 16.04 LTS) with https access.

This task took me three hours reading a lot of web pages and lots of trial and error. To make your life easier this is what you need to do to setup a Jenkins CI instance using your AWS account.

I've tested this process and it took exactly *5 minutes* to get to the https login screen of the new jenkins instance. Most of that time is waiting for the scripted installation of components on the AWS instance.

##Create an EC2 instance
* open AWS Console in browser
* go to EC2
* select **Launch Instance**
* select **Ubuntu Server 16.04 LTS**
* select **t2.micro**
* select **Configure Instance Details**
* tick **Enable termination protection**
* select **Add Storage**
* change size to preferred (I use 100GB for our large enterprise builds)
* select **Add Tags**
* set value to *Jenkins*
* select **Configure Security Group**
* add rule *HTTPS*
* select **Review and launch**
* select a key pair
* select **Launch Instance**
* In EC2 go to instances, once instance running then select instance and click **Connect**
* copy ssh command in the example to terminal and run (you'll need your referenced key file present in that directory)

##Instructions
Login to the instance using the ssh command mentioned above. Then run:
```bash
wget https://raw.githubusercontent.com/davidmoten/jenkins-ec2-https/master/setup.sh
```
Now edit the file `setup.sh` and edit the top block of parameters with the values you want to see in the generated certificate for jenkins website.
```bash
./setup.sh
```
Now go to https://your_instance in the browser and paste in the last line output by the `setup.sh` script into the administration password in the browser. If the browser times out go to the same url again (make sure it's https). That's it!

##Sources
* https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Ubuntu
* https://github.com/hughperkins/howto-jenkins-ssl
* https://wiki.jenkins-ci.org/display/JENKINS/Running+Jenkins+behind+Apache
