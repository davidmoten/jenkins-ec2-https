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

##Instructions
* copy the contents of [setup.sh](setup.sh) to a file `setup.sh` in the `/home/ubuntu` directory (that's where you are when you login to the instance)
* Then 
```bash
chmod +x setup.sh
./setup.sh
```
* Optionally edit `create-certs.sh` and update CA_PASSWORD and certificate fields (especially the CN field which is the hostname).
* Then
```bash
./create-certs.sh
```
Now go to https://your_instance in the browser and paste in the last line output by the `create-certs.sh` script into the administration password in the browser. If the browser times out go to the same url again (make sure it's https). That's it!
