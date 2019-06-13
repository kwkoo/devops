# DevOps Demo

To setup the demo, you will need to run 2 shell scripts.

First, clone this repo to your local disk that will be able to use oc command to access to your OCP server.

Then, run the init.sh script to initialize the demo environment. This script will create a few OCP projects to represent
dev, test, prod environments. A tools project will be created to keep the CI/CD tools such as jenkins, gogs and etc.

Once the demo environment has been provisioned. Make sure the PODs under the tools project are all ready running without error. 
Run the initDemoData.sh script to initilize the required demo data.

More details of some manual pre-requisition configuration steps are mentioned in the script. 
Please run init.sh -h and initDemoData.sh -h to view more details.


## Notes
1. Sometime, you may want to increase the resource limits for Jenkins and Nexus. Especially nexus will need minimum 2GB RAM to run
properly. Allocation of 4GB will be the best. With lower memory allocation, Nexus will always failed and restart and caused the build
always failed half way. Higher memory also ensure Repo cache can be cached sufficiently and the builds will take shorter time to complete, 
when you demo the Jenkins builds.
2. Do a chmod +x init.sh if the script is without execution permission.
3. Do a chmod +x initDemoData.sh if the script is without execution permission.


## To Do
