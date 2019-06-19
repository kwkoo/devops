# DevOps Demo

## Installation
In order to deploy this demo, you will need to clone this repo to your local
machine. The local machine would need to have access to the `oc` tool.

If you are deploying this demo to RHPDS and you are running this on the
bastion host, everything should be autodetected and you should not need to
change anything.

However, if you are deploying this somewhere else, you should edit the
`Makefile` and ensure that the following variables are set correctly:

* `ON_RHPDS`
* `MASTER_NODE_URL`
* `USERNAME`
* `PASSWORD`
* `DOMAIN_NAME`

Once you've defined the variables in the `Makefile`, kick off the install by
executing `make`.

This should set the whole demo up. After the installation, the only steps
you'll need to perform manually would be to setup a webhook from gogs to
jenkins.


## Other useful `make` targets

* `make clean` - Deletes all relevant projects.
* `make console` - Opens a web browser to the OpenShift web console.
* `make gogs` - Opens a web browser to the Gogs web console.
* `make jenkins` - Opens a web browser to the Jenkins web console.

## Video
[Demo Video](https://www.dropbox.com/s/31bzz7ccrb9o0hz/OCP%20CICD%20Demo%202.mp4?dl=0)

## Screen Shots
### Projects
![Projects](https://github.com/chengkuangan/devops/blob/master/docs/images/projects.png?raw=true)
### CI/CD Tools
![CI/CD Tools](https://github.com/chengkuangan/devops/blob/master/docs/images/cicdtools.png?raw=true)
### Gogs with nationalparks Sample Source Codes
![Gogs](https://github.com/chengkuangan/devops/blob/master/docs/images/gogs-nationalparks.png?raw=true)
### Gogs Git Hooks Settings
![Gogs Settings](https://github.com/chengkuangan/devops/blob/master/docs/images/gogs-nationalparks-settings.png?raw=true)
### Nexus3 Repositories
![Nexus Repo](https://github.com/chengkuangan/devops/blob/master/docs/images/nexus3-repo.png?raw=true)
### Jenkins Console
![Jenkins Console](https://github.com/chengkuangan/devops/blob/master/docs/images/jenkins-console.png?raw=true)
### Jenkins Settings
![Jenkins Settings](https://github.com/chengkuangan/devops/blob/master/docs/images/jenkins-settings.png?raw=true)
### Jenkins User Token
![Jenkins User Token](https://github.com/chengkuangan/devops/blob/master/docs/images/jenkins-user-token.png?raw=true)
### Jenkins Builds
![Jenkins Builds](https://github.com/chengkuangan/devops/blob/master/docs/images/jenkins-build.png?raw=true)
### nationalparks Image Build at Dev Environment
![Jenkins User Token](https://github.com/chengkuangan/devops/blob/master/docs/images/imagebuild-dev.png?raw=true)
### Blue Apps is Serving Request
![Jenkins User Token](https://github.com/chengkuangan/devops/blob/master/docs/images/green-apps.png?raw=true)
### Green Apps is Serving Request
![Jenkins User Token](https://github.com/chengkuangan/devops/blob/master/docs/images/blue-apps.png?raw=true)