# DevOpsDemo
This README is being updated at the moment. 
For instrucstions for how to setup this demo, please refer to the init.sh and initGogs.sh in the bin folder. 

1. Clone this github repos into your local drive.
2. Change directory to bin
2. chmod +x init.sh initGogs.sh
3. Run ./init.sh -h to view the instructions.
4. Run ./initGogs.sh -h to view the instructions.

## Notes
1. To configure git hook, refers to the document at the notes folder

## To Do
1. Fix the Gogs app.ini ROOT_URL setting. This should be configured to the generated public host name. Generated route host name is not available during POD creation, thus the only way to configure this is after the POD has been created and started
2. Change from using shell script to ansible playbook for deploying this demo.
3. Need to complete the parksmap deployment template.
4. Need to add in A/B testing scenario.
