#!/bin/bash

#================== Global Variables  ==================

PROJ_NAME_PREFIX='gck-'
PROJ_TOOLS_NAME='tools'
PROJ_DEV_NAME='dev'
PROJ_TEST_NAME='test'
PROJ_PROD_NAME='prod'
OCP_WILDCARD_DNSNAME=.apps.na1.openshift.opentlc.com
NEXUS_SERVICE_NAME=nexus3
NATIONALPARKS_APPLICATION_NAME=nationalparks
PARKSMAP_APPLICATION_NAME=parksmap-web

MASTER_NODE_URL=""
USERNAME=""
PASSWORD=""
DEMO_SCOPE="nmp"
DELETE_ALL_PROJECT="true"
DELETE_RELATED_PROJECT="false"
CONFIRM_DELETE_PROJECT="Yes"
CREATE_TOOLS="false"
CREATE_NATIONALPARKS="false"
CREATE_PARKSMAP="false"
CREATE_MLBPARKS="false"
LOGOUT_WHEN_DONE="false"

UNINSTALL="false"

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
#    echo "       np - Create demo with both nationalparks and parksmap-web."
#    echo "       mp - Create demo with both mlbparks and parksmap-web."
#    echo "       nmp - Default. Create demo with nationalparks, mlbparks and parksmap-web"
    echo "--delete-all-project       Optional. Default: $DELETE_ALL_PROJECT. Specify --delete-all-project true will delete all existing projects with the same project name."
    echo "--delete-related-project   Optional. Default: $DELETE_RELATED_PROJECT. Setting this to true will superceded --delete-all-project"
    echo "--project-name-prefix      Optional. Default: $PROJ_NAME_PREFIX. Specify a prefix to avoid project name conflict in shared environment."
    echo "-logout                    Logout from Openshift when the command is completed. Default is true, specify false to ignore logout."
    echo "--wildcard-dnsname         A default wildcard DNS Name used to suffix the exposed routes DNS Name. Defauted to $OCP_WILDCARD_DNSNAME"
    echo "-uninstall                  Optional. Default: $UNINSTALL. True or false. Uninstall the demo."
    echo
}

function printUsage(){
    echo
    echo "This command initialize a CI/CD demo in OpenShift based on Parskmap demo codes."
    echo "It has been tested in OpenShift 3.5"
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
    echo -e "\t- parksmap-web"
    echo -e "\t- mlbparks"
    echo -e "Production Environment will simulate blue/green deployment."
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
    echo "1. Please ensure sufficient PV is available for the PODs required PVs."
    echo
}

function printAdditionalRemarks(){

    echo "================================ Post-Deployment Steps ================================"
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
    echo "================================ Additional Manual Steps Required ================================"
    echo
    echo "Some of the steps cannot be automated or too troublesome to be automated using this script, thus manual "
    echo "manual steps needed to be peform in order to complete the demo setup. Please follow the steps below: "
    echo
    echo "1. Repository need to be created in gogs POD for parksmap-web, nationalparks and mlbparks. Once these "
    echo "   are created, please run the initGog.sh command to download the sample source codes and push them to "
    echo "   these repository in OCP's gogs containers. Only do this when the gogs POP is properly provisioned and "
    echo "   actively available."
    echo
    echo "2. To enable git hook, please refers to following guide:"
    echo "   ../notes/githook-config.txt"
    echo
    echo "For Information Only:"
    echo
    echo "The following changes were made to any original source taken from 3rd party in order to make this demo works."
    echo "This section is for information only, no addiional steps need to be taken."
    echo
    echo "1. SNAPSHOOT/RELEASE version tags is removed from pom.xml as per the following and move the section to the top"
    echo "of the pom.xml for nationalparks, mlbparks and parksmap-web projects."
    echo
    echo -e "<groupId>com.openshift.evg.roadshow</groupId>"
    echo -e "<artifactId>parksmap-web</artifactId>"
    echo -e "<version>1.0.0</version>"
    echo -e "<packaging>jar</packaging>"
    echo
    echo "2. For sonarqube usage, the following plugins is added into the pom.xml in order to allow mvn compilation to "
    echo "   completed successfully."
    echo
    echo -e "<plugin>"
    echo -e "  <groupId>org.sonarsource.scanner.maven</groupId>"
    echo -e "  <artifactId>sonar-maven-plugin</artifactId>"
    echo -e "  <version>3.0.1</version>"
    echo -e "</plugin>"
    echo -e "<plugin>"
    echo -e "  <groupId>org.jacoco</groupId>"
    echo -e "  <artifactId>jacoco-maven-plugin</artifactId>"
    echo -e "  <version>0.7.6.201602180812</version>"
    echo -e "  <executions>"
    echo -e "    <execution>"
    echo -e "      <id>default-prepare-agent</id>"
    echo -e "      <goals>"
    echo -e "        <goal>prepare-agent</goal>"
    echo -e "      </goals>"
    echo -e "    </execution>"
    echo -e "    <execution>"
    echo -e "      <id>default-report</id>"
    echo -e "      <phase>prepare-package</phase>"
    echo -e "      <goals>"
    echo -e "        <goal>report</goal>"
    echo -e "      </goals>"
    echo -e "    </execution>"
    echo -e "  </executions>"
    echo -e "</plugin>"
    echo
    echo "3. Remember to change the nexus URL/hostname if it is different from what has been configured in the following "
    echo "   files in the repositories: "
    echo "   - nexus_settings.xml"
    echo "   - nexus_openshift_settings.xml"
    echo
    echo "4. Double check that the hostname for all the services are correct in the Jenkinsfile based on your environment."
    echo
    echo "5. Make sure Sonarqube is properly configured and loaded, something due to internet connection and limited server"
    echo "   resources, the Sonarqube is created without proper default rules and quality profiles, this will cause the "
    echo "   Jenkins Pipelines failed."
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
    echo "OCP_WILDCARD_DNSNAME = $OCP_WILDCARD_DNSNAME"
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
    echo "DELETE_ALL_PROJECT = $DELETE_ALL_PROJECT"
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
      elif [ "$1" == "--delete-all-project" ]; then
        shift
        DELETE_ALL_PROJECT="$1"
      elif [ "$1" == "--delete-related-project" ]; then
        shift
        DELETE_RELATED_PROJECT="$1"
      elif [ "$1" == "--project-name-prefix" ]; then
        shift
        PROJ_NAME_PREFIX="$1"
      elif [ "$1" == "-logout" ]; then
        shift
        LOGOUT_WHEN_DONE="$1"
      elif [ "$1" == "--wildcard-dnsname" ]; then
        shift
        OCP_WILDCARD_DNSNAME="$1"
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


    if [ "$DELETE_ALL_PROJECT" = "true" ]; then
        echo -e "Confirm to delete all existing projects related to this demo (Yes/No) ?"
        read CONFIRM_DELETE_PROJECT
    fi

    if [[ "$CONFIRM_DELETE_PROJECT" == "No" ]] || [[ "$CONFIRM_DELETE_PROJECT" == "no" ]]; then
        echo "Ok, no going to delete the projects...abort command..."
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

if [ "$DELETE_ALL_PROJECT" = "true" ]; then
    if [ "$DELETE_RELATED_PROJECT" = "true" ]; then
        echo
        echo "---> Deleting related existing projects if exists..."
        echo
        if [ "$CREATE_TOOLS" = "true" ]; then
            oc delete project $PROJ_TOOLS_NAME
        fi
        if [[ "$CREATE_NATIONALPARKS" = "true" ]] || [[ "$CREATE_MLBPARKS" = "true" ]] || [[ "$CREATE_PARKSMAP" = "true" ]] ; then
            oc delete project $PROJ_DEV_NAME
            oc delete project $PROJ_TEST_NAME
            oc delete project $PROJ_PROD_NAME
        fi
    else
        echo
        echo "---> Deleting existing projects if exists..."
        echo
        oc delete project $PROJ_TOOLS_NAME
        oc delete project $PROJ_DEV_NAME
        oc delete project $PROJ_TEST_NAME
        oc delete project $PROJ_PROD_NAME
    fi

    echo "Wait for 60 seconds to allow the projects to be deleted completely..."
    sleep 60
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
    oc new-app -n $PROJ_DEV_NAME --allow-missing-imagestream-tags=true -f ../templates/nationalparks-persistent-templates.yaml -p IMAGE_NAME=DevelopmentReady -p IMAGE_PROJECT_NAME=$PROJ_DEV_NAME -p MAVEN_MIRROR_URL=http://$NEXUS_SERVICE_NAME:8081/repository/maven-all-public -p APPLICATION_NAME=$NATIONALPARKS_APPLICATION_NAME
    # label nationalparks as parksmap backend
    oc label service $NATIONALPARKS_APPLICATION_NAME type=parksmap-backend -n $PROJ_DEV_NAME
fi

### --------- parksmap-web configurations

if [ "$CREATE_PARKSMAP" = "true" ]; then
    echo
    echo "------> Provisioning parkmaps-web now..."
    echo
    oc new-app -n $PROJ_DEV_NAME --allow-missing-imagestream-tags=true -f ../templates/parksmap-web-dev-templates.yaml -p IMAGE_NAME=DevelopmentReady -p IMAGE_PROJECT_NAME=$PROJ_DEV_NAME -p MAVEN_MIRROR_URL=http://$NEXUS_SERVICE_NAME:8081/repository/maven-all-public -p APPLICATION_NAME=$PARKSMAP_APPLICATION_NAME
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

    oc new-app -n $PROJ_PROD_NAME --allow-missing-imagestream-tags=true -f ../templates/nationalparks-prod-templates.yaml -p IMAGE_NAME=ProdReady -p IMAGE_PROJECT_NAME=$PROJ_DEV_NAME -p APPLICATION_NAME=$PROD_NATIONALPARKS_SERVER_GREEN
    oc new-app -n $PROJ_PROD_NAME --allow-missing-imagestream-tags=true -f ../templates/nationalparks-prod-templates.yaml -p IMAGE_NAME=ProdReady -p IMAGE_PROJECT_NAME=$PROJ_DEV_NAME -p APPLICATION_NAME=$PROD_NATIONALPARKS_SERVER_BLUE
    oc new-app -n $PROJ_PROD_NAME -f ../templates/nationalparks-mongodb-prod-templates.yaml

    oc env dc/$PROD_NATIONALPARKS_SERVER_GREEN PROD_ENV_VERSION="Green Server" -n $PROJ_PROD_NAME
    oc env dc/$PROD_NATIONALPARKS_SERVER_BLUE PROD_ENV_VERSION="Blue Server" -n $PROJ_PROD_NAME

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
