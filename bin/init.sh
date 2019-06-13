#!/bin/bash

#================== Global Variables  ==================

PROJ_NAME_PREFIX='gck-'
PROJ_TOOLS_NAME='tools'
PROJ_DEV_NAME='dev'
PROJ_TEST_NAME='test'
PROJ_PROD_NAME='prod'
DOMAIN_NAME=apps.na1.openshift.opentlc.com
NEXUS_SERVICE_NAME=nexus3
NATIONALPARKS_APPLICATION_NAME=nationalparks
PARKSMAP_APPLICATION_NAME=parksmap-web

MASTER_NODE_URL=""
USERNAME=""
PASSWORD=""
DEMO_SCOPE="nmp"
CREATE_TOOLS="false"
CREATE_NATIONALPARKS="false"
CREATE_PARKSMAP="false"
CREATE_MLBPARKS="false"
LOGOUT_WHEN_DONE="false"
UNINSTALL="false"
CONFIRM_UNINSTALL=""

#================== Functions ==================

function printCmdUsage(){
    echo
    echo "Command Usage: init.sh -url <OCP Master URL> -u <username> -p <password> [options]"
    echo "-h                         Print the help information for this command."
    echo "-url                       Master node URL"
    echo "-u                         Username to login to OCP"
    echo "-p                         Password to login to OCP"
    echo
    echo "[options]"
    echo "-s                         Demo scope to create. "
    echo "                           t - Create demo with tools."
    echo "                           n - Create demo with nationaparks."
    echo "                           p - Create demo with parksmap-web."
    echo "                           m - Create demo with mlbparks."
    echo "-np                        Optional. Default: $PROJ_NAME_PREFIX. Specify a project name prefix to avoid project name conflict in shared environment."
    echo "-logout                    Optional. Default: $LOGOUT_WHEN_DONE. Logout from Openshift when the command is completed."
    echo "-d                         Optional. Defaut: $DOMAIN_NAME. A default ocp domain Name."
    echo "-uninstall                 Optional. Default: $UNINSTALL. True or false. Uninstall the demo."
    echo
}

function printUsage(){
    echo
    echo "This command initialize a CI/CD demo in OpenShift based on Parskmap demo codes."
    echo "It has been tested working in OpenShift 3.x and 4.x"
    echo
    echo "The following PODs will be provisioned and configured based on the arguments specified:"
    echo
    echo -e "PODs in Tools Project:"
    echo -e "\t- Gogs"
    echo -e "\t- Jenkins"
    echo -e "\t- Sonarqube"
    echo -e "\t- Nexus3"
    echo
    echo -e "PODs in Development, Test and Production Environment Projects"
    echo -e "\t- nationalparks"
    echo
    echo -e "Production Environment will simulate a simple blue/green deployment. Not bullet proof and but showcase the posibility of how blue/green"
    echo -e "deployment can be done in  OCP. There are many approaches to do this."
    printCmdUsage
    echo
    printAdditionalRemarks
    echo
    printImportantNoteBeforeExecute
    echo
}

function printImportantNoteBeforeExecute(){
    echo
    echo "Please ensure the following pre-requisition are met before proceeding..."
    echo
    echo "1. Please ensure sufficient PV is available for the PODs required PVs."
    echo
}

function printAdditionalRemarks(){
    echo -e "\e[0;31 RED"
    echo "================================ Post-Deployment Steps ================================"
    echo -e "\e[0m"
    echo "Please perform the following steps to complete the demo setup:"
    echo
    echo "Gogs Sample Source Codes"
    echo "1. After the gogs POD is ready. Access to the console and register a new user."
    echo 
    echo "Jenkins Pre-Req Configuration"
    echo "1. Go to the Jenkins console and register a new user."
    echo "2. Login Jenkins with the new user. On the right upper site of the top menu, click beside the username to bring up the drop-down menu. Choose Configure on "
    echo "   the drop-menu."
    echo "3. Add a new Token under the API Token section. Keep note of this token, we will be going to use it. Click Save to proceed." 
    echo 
    echo "Configure and loading demo data into the demo environment."
    echo "1. Run the provided initDemoData.sh to configure Gogs and Jenkins with the username and token created in the previous steps."
    echo
}

function printVariables(){
    echo
    echo "The following information will be used to create the demo:"
    echo
    echo "PROJ_NAME_PREFIX = $PROJ_NAME_PREFIX"
    echo "PROJ_TOOLS_NAME = $PROJ_TOOLS_NAME"
    echo "PROJ_DEV_NAME = $PROJ_DEV_NAME"
    echo "PROJ_TEST_NAME = $PROJ_TEST_NAME"
    echo "PROJ_PROD_NAME = $PROJ_PROD_NAME"
    echo "DOMAIN_NAME = $DOMAIN_NAME"
    echo "NEXUS_SERVICE_NAME = $NEXUS_SERVICE_NAME"
    echo "NATIONALPARKS_APPLICATION_NAME = $NATIONALPARKS_APPLICATION_NAME"
    echo "PARKSMAP_APPLICATION_NAME = $PARKSMAP_APPLICATION_NAME"
    echo "MASTER_NODE_URL = $MASTER_NODE_URL"
    echo "USERNAME = $USERNAME"
    echo "PASSWORD = *********"
    echo "DEMO_SCOPE = $DEMO_SCOPE"
    echo "CREATE_TOOLS = $CREATE_TOOLS"
    echo "CREATE_NATIONALPARKS = $CREATE_NATIONALPARKS"
    echo "CREATE_PARKSMAP = $CREATE_PARKSMAP"
    echo "CREATE_MLBPARKS = $CREATE_MLBPARKS"
    echo
}

function processArguments(){

    if [ $# -eq 0 ]; then
        printCmdUsage
        exit 0
    fi

    while (( "$#" )); do
      if [ "$1" == "-h" ]; then
        printUsage
        exit 0
      elif [ "$1" == "-url" ]; then
        shift
        MASTER_NODE_URL="$1"
      elif [ "$1" == "-u" ]; then
        shift
        USERNAME="$1"
      elif [ "$1" == "-p" ]; then
        shift
        PASSWORD="$1"
      elif [ "$1" == "-s" ]; then
        shift
        DEMO_SCOPE="$1"
      elif [ "$1" == "-np" ]; then
        shift
        PROJ_NAME_PREFIX="$1"
      elif [ "$1" == "-logout" ]; then
        shift
        LOGOUT_WHEN_DONE="$1"
      elif [ "$1" == "-d" ]; then
        shift
        DOMAIN_NAME="$1"
      else
        echo "Unknown argument: $1"
        printCmdUsage
        exit 0
      fi
      shift
    done

    if [ "$MASTER_NODE_URL" = "" ]; then
        echo "Missing -url argument. Master node URL is required."
        exit 0
    fi

    if [ "$USERNAME" = "" ]; then
        echo "Missing -u argument. Username is required."
        exit 0
    fi

    if [ "$PASSWORD" = "" ]; then
        echo "Missing -p argument. Password is required."
        exit 0
    fi

    for (( i=0 ; i < ${#DEMO_SCOPE} ; i++ )) {
        if [ "${DEMO_SCOPE:i:1}" = "t" ]; then
            CREATE_TOOLS="true"
        elif [ "${DEMO_SCOPE:i:1}" = "n" ]; then
            CREATE_NATIONALPARKS="true"
        elif [ "${DEMO_SCOPE:i:1}" = "p" ]; then
            CREATE_PARKSMAP="true"
        elif [ "${DEMO_SCOPE:i:1}" = "m" ]; then
            CREATE_MLBPARKS="true"
        fi
    }

    PROJ_TOOLS_NAME=$PROJ_NAME_PREFIX'tools'
    PROJ_DEV_NAME=$PROJ_NAME_PREFIX'dev'
    PROJ_TEST_NAME=$PROJ_NAME_PREFIX'test'
    PROJ_PROD_NAME=$PROJ_NAME_PREFIX'prod'


    if [ "$UNINSTALL" = "true" ]; then
        echo -e "Confirm Uninstall the demo environment? (Yes/No)"
        read CONFIRM_UNINSTALL
    fi

    if [[ "$CONFIRM_UNINSTALL" == "No" ]] || [[ "$CONFIRM_UNINSTALL" == "no" ]]; then
        echo "Ok, no going to uninstall the demo...abort command..."
        exit 0
    fi

}

######################################################################################################
####################################### It starts from here ##########################################
######################################################################################################

#================== Process Command Line Arguments ==================

processArguments $@
printVariables
printImportantNoteBeforeExecute
echo
echo "Press ENTER (OR Ctrl-C to cancel) to proceed..."
read bc

oc login -u $USERNAME -p $PASSWORD $MASTER_NODE_URL

#================== Delete Projects if Found ==================
# Does not care whether project exists or not, just call, if not found, ignore the error.

if [ "$UNINSTALL" = "true" ]; then
    echo
    echo "---> Deleting existing projects if exists..."
    echo
    oc delete project $PROJ_TOOLS_NAME
    oc delete project $PROJ_DEV_NAME
    oc delete project $PROJ_TEST_NAME
    oc delete project $PROJ_PROD_NAME
    echo "---> Projects deleted..."
    exit 0
fi

#================== Create projects required with neccessary permissions ==================

echo
echo "---> Creating all required projects now..."
echo

if [ "$CREATE_TOOLS" = "true" ]; then
    oc new-project $PROJ_TOOLS_NAME --display-name="Tools"
fi

if [[ "$CREATE_NATIONALPARKS" = "true" ]] || [[ "$CREATE_MLBPARKS" = "true" ]] || [[ "$CREATE_PARKSMAP" = "true" ]] ; then
    oc new-project $PROJ_DEV_NAME --display-name="Development Environment"
    oc new-project $PROJ_PROD_NAME --display-name="Production Environment"
    oc new-project $PROJ_TEST_NAME --display-name="Test Environment"
fi

echo
echo "---> Adding all necessary users and system accounts permissions..."
echo

if [[ "$CREATE_NATIONALPARKS" = "true" ]] || [[ "$CREATE_MLBPARKS" = "true" ]] || [[ "$CREATE_PARKSMAP" = "true" ]] ; then
    oc policy add-role-to-user edit system:serviceaccount:$PROJ_TOOLS_NAME:jenkins -n $PROJ_DEV_NAME
    oc policy add-role-to-user edit system:serviceaccount:$PROJ_TOOLS_NAME:jenkins -n $PROJ_PROD_NAME
    oc policy add-role-to-user edit system:serviceaccount:$PROJ_TOOLS_NAME:jenkins -n $PROJ_TEST_NAME

    oc policy add-role-to-user system:image-puller system:serviceaccount:$PROJ_TEST_NAME:default -n $PROJ_DEV_NAME
    oc policy add-role-to-user system:image-puller system:serviceaccount:$PROJ_PROD_NAME:default -n $PROJ_DEV_NAME
    oc policy add-role-to-user system:image-puller system:serviceaccount:$PROJ_PROD_NAME:default -n $PROJ_TEST_NAME

    # parksmap-web requires view permission
    oc policy add-role-to-user view system:serviceaccount:$PROJ_DEV_NAME:default -n $PROJ_DEV_NAME
    oc policy add-role-to-user view system:serviceaccount:$PROJ_TEST_NAME:default -n $PROJ_TEST_NAME
    oc policy add-role-to-user view system:serviceaccount:$PROJ_PROD_NAME:default -n $PROJ_PROD_NAME
fi

#================== Deploy Gogs ==================
### Reference: https://github.com/OpenShiftDemos/gogs-openshift-docker

if [ "$CREATE_TOOLS" = "true" ]; then

    echo
    echo "---> Provisioning gogs now..."
    echo
    oc new-app -f https://raw.githubusercontent.com/chengkuangan/templates/master/gogs-persistent-template.yaml -p SKIP_TLS_VERIFY=true -n $PROJ_TOOLS_NAME 

    #================== Deploy Nexus3 ==================

    echo
    echo "---> Provisioning nexus3 now..."
    echo
    oc new-app -f https://raw.githubusercontent.com/chengkuangan/templates/master/nexus3-persistent-templates.yaml -n $PROJ_TOOLS_NAME
    
    #================== Deploy SornarQube ==================

    echo
    echo "---> Provisioning sonarqube now..."
    echo
    ## oc new-app -f ../templates/sonarqube-persistent-templates.yaml -n $PROJ_TOOLS_NAME

    #================== Deploy Jenkins ==================

    echo
    echo "---> Provisioning Jenkins now..."
    echo
    oc new-app jenkins-persistent -n $PROJ_TOOLS_NAME

fi

#================== Prepares Dev Environment ==================

echo
echo "---> Provisioning development environment objects now..."
echo

### --------- nationalparks configurations

if [ "$CREATE_NATIONALPARKS" = "true" ]; then
    echo
    echo "------> Provisioning nationalparks now..."
    echo
    oc new-app -n $PROJ_DEV_NAME --allow-missing-imagestream-tags=true -f ../templates/nationalparks-persistent-templates.yaml -p IMAGE_NAME=DevelopmentReady -p IMAGE_PROJECT_NAME=$PROJ_DEV_NAME -p APPLICATION_NAME=$NATIONALPARKS_APPLICATION_NAME
    # label nationalparks as parksmap backend
    oc label service $NATIONALPARKS_APPLICATION_NAME type=parksmap-backend -n $PROJ_DEV_NAME
fi

### --------- parksmap-web configurations

if [ "$CREATE_PARKSMAP" = "true" ]; then
    echo
    echo "------> Provisioning parkmaps-web now..."
    echo
    oc new-app -n $PROJ_DEV_NAME --allow-missing-imagestream-tags=true -f ../templates/parksmap-web-dev-templates.yaml -p IMAGE_NAME=DevelopmentReady -p IMAGE_PROJECT_NAME=$PROJ_DEV_NAME -p APPLICATION_NAME=$PARKSMAP_APPLICATION_NAME
fi

#================== Prepares Test Environment ==================

echo
echo "---> Provisioning test environment objects now..."
echo

### --------- nationalparks configurations
if [ "$CREATE_NATIONALPARKS" = "true" ]; then
    echo
    echo "------> Provisioning nationalparks now..."
    echo
    oc new-app -n $PROJ_TEST_NAME --allow-missing-imagestream-tags=true -f ../templates/nationalparks-persistent-nobuild-templates.yaml -p IMAGE_NAME=TestReady -p IMAGE_PROJECT_NAME=$PROJ_DEV_NAME

    # label nationalparks as parksmap backend
    oc label service $NATIONALPARKS_APPLICATION_NAME type=parksmap-backend -n $PROJ_TEST_NAME
fi

if [ "$CREATE_PARKSMAP" = "true" ]; then
### --------- parksmap-web configurations
    echo
    echo "------> Provisioning parksmap-web now..."
    echo
    oc new-app -n $PROJ_TEST_NAME --allow-missing-imagestream-tags=true -f ../templates/parksmap-web-test-templates.yaml -p IMAGE_NAME=TestReady -p IMAGE_PROJECT_NAME=$PROJ_DEV_NAME
fi

#================== Prepares Prod Environment ==================

echo
echo "---> Provisioning Production environment objects now..."
echo

### --------- nationalparks configurations
if [ "$CREATE_NATIONALPARKS" = "true" ]; then

    echo
    echo "------> Provisioning nationalparks now..."
    echo

    PROD_NATIONALPARKS_SERVER_GREEN=nationalparks-green
    PROD_NATIONALPARKS_SERVER_BLUE=nationalparks-blue

    oc new-app -n $PROJ_PROD_NAME --allow-missing-imagestream-tags=true -f ../templates/nationalparks-prod-templates.yaml -p IMAGE_NAME=ProdReady -p IMAGE_PROJECT_NAME=$PROJ_DEV_NAME -p APPLICATION_NAME=$PROD_NATIONALPARKS_SERVER_GREEN -p PROD_ENV_VERSION="Green"
    oc new-app -n $PROJ_PROD_NAME --allow-missing-imagestream-tags=true -f ../templates/nationalparks-prod-templates.yaml -p IMAGE_NAME=ProdReady -p IMAGE_PROJECT_NAME=$PROJ_DEV_NAME -p APPLICATION_NAME=$PROD_NATIONALPARKS_SERVER_BLUE -p PROD_ENV_VERSION="Blue"
    oc new-app -n $PROJ_PROD_NAME -f ../templates/nationalparks-mongodb-prod-templates.yaml

    oc patch dc $PROD_NATIONALPARKS_SERVER_GREEN --patch "{\"spec\": { \"triggers\": []}}" -n $PROJ_PROD_NAME
    oc patch dc $PROD_NATIONALPARKS_SERVER_BLUE --patch "{\"spec\": { \"triggers\": []}}" -n $PROJ_PROD_NAME
    oc expose svc/$PROD_NATIONALPARKS_SERVER_GREEN --name=nationalparks-bluegreen -n $PROJ_PROD_NAME
fi

### --------- parksmap-web configurations
if [ "$CREATE_PARKSMAP" = "true" ]; then

    echo
    echo "------> Provisioning parksmap-web now..."
    echo

    PROD_PARKSMAP_SERVER_GREEN=parksmap-web-green
    PROD_PARKSMAP_SERVER_BLUE=parksmap-web-blue

    oc new-app -n $PROJ_PROD_NAME --allow-missing-imagestream-tags=true -f ../templates/nationalparks-prod-templates.yaml -p IMAGE_NAME=ProdReady -p IMAGE_PROJECT_NAME=$PROJ_DEV_NAME -p APPLICATION_NAME=$PROD_PARKSMAP_SERVER_GREEN
    oc new-app -n $PROJ_PROD_NAME --allow-missing-imagestream-tags=true -f ../templates/nationalparks-prod-templates.yaml -p IMAGE_NAME=ProdReady -p IMAGE_PROJECT_NAME=$PROJ_DEV_NAME -p APPLICATION_NAME=$PROD_PARKSMAP_SERVER_BLUE

    oc expose svc/$PROD_PARKSMAP_SERVER_GREEN --name=parksmap-web-bluegreen -n $PROJ_PROD_NAME
fi

#================== Other Settings ==================

if [ "$LOGOUT_WHEN_DONE" = "true" ]; then
    oc logout
fi

printAdditionalRemarks

echo
echo "==============================================================="
echo "Well, the demo should have been deployed and configured now... "
echo "==============================================================="
echo

######################################################################################################
####################################### It ENDS  here ################################################
######################################################################################################
