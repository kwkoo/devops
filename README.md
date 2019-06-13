# DevOps Demo

To setup the demo, you will need to run 2 shell scripts.

First, clone this repo to your local disk that will be able to use oc command to access to your OCP server.

Then, changed path to bin folder and run ./init.sh script to initialize the demo environment. This script will create a few OCP projects to represent
dev, test, prod environments. A tools project will be created to keep the CI/CD tools such as jenkins, gogs and etc.

Once the demo environments have been provisioned. Make sure all the PODs under the tools project are all ready running without error. 
Run the ./initDemoData.sh script to initilize the required demo data.

There are some manual steps required before running the initDemoData.sh script. Please run ./initDemoData.sh -h for more details.

## Notes
1. You may want to increase the resource limits for Jenkins and Nexus. Especially Nexus will need minimum 3GB RAM to run
properly. These resource limits can be changed from the init.sh script using parameters before provisioning. 
Allocation of 4GB will be the best for smooth demo experience. With lower memory allocation, Jenkins build will always fail caused by 
Nexus keep restarting in the background. Higher memory ensure maven/build are cached once the first built has been done, which helps to cut down
a lot of build time for all the subsequence builds. If you restarted the POD or server, make sure you have done a first build before the actual
demo.
2. Do a chmod +x init.sh if the script is without execution permission.
3. Do a chmod +x initDemoData.sh if the script is without execution permission.


## To Do
To be updated.

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
### Green Apps is Serving Request
![Jenkins User Token](https://github.com/chengkuangan/devops/blob/master/docs/images/green-apps.png?raw=true)
### Blue Apps is Serving Request
![Jenkins User Token](https://github.com/chengkuangan/devops/blob/master/docs/images/blue-apps.png?raw=true)