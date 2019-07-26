BASE=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# t - create tools, n - create national parks, p - create parks map, m - create MLB parks
DEMO_SCOPE=tnmp
PROJ_NAME_PREFIX=
PROJ_TOOLS_SUFFIX=tools
PROJ_DEV_SUFFIX=dev
PROJ_TEST_SUFFIX=test
PROJ_PROD_SUFFIX=prod
NEXUS_SERVICE_NAME=nexus3
NATIONALPARKS_APPLICATION_NAME=nationalparks
PARKSMAP_APPLICATION_NAME=parksmap-web
LOGOUT_WHEN_DONE=0

# If you use something other than gogs / gogs, you will need to create the
# user manually in gogs. The creategogsuser target hardcodes the password to
# gogs.
#
GOGSUSER=gogs
GOGSPASSWORD=gogs


PROD_NATIONALPARKS_SERVER_GREEN=nationalparks-green
PROD_NATIONALPARKS_SERVER_BLUE=nationalparks-blue
PROD_PARKSMAP_SERVER_GREEN=parksmap-web-green
PROD_PARKSMAP_SERVER_BLUE=parksmap-web-blue

CREATE_ENVIRONMENT_PROJ=0
ifneq (,$(findstring t,$(DEMO_SCOPE)))
	CREATE_TOOLS=1
else
	CREATE_TOOLS=0
endif

ifneq (,$(findstring n,$(DEMO_SCOPE)))
	CREATE_NATIONALPARKS=1
	CREATE_ENVIRONMENT_PROJ=1
else
	CREATE_NATIONALPARKS=0
endif

ifneq (,$(findstring p,$(DEMO_SCOPE)))
	CREATE_PARKSMAP=1
	CREATE_ENVIRONMENT_PROJ=1
else
	CREATE_PARKSMAP=0
endif

ifneq (,$(findstring m,$(DEMO_SCOPE)))
	CREATE_MLBPARKS=1
	CREATE_ENVIRONMENT_PROJ=1
else
	CREATE_MLBPARKS=0
endif

# Set this to 1 if running on RHPDS, 0 otherwise.
ON_RHPDS=$(shell $(BASE)/scripts/onrhpds)

MASTER_NODE_URL=$(shell $(BASE)/scripts/masterurl)

# Try to autodetect variables.
ifeq ($(ON_RHPDS), 1)
	USERNAME=user1
	PASSWORD=openshift
else
	USERNAME=developer
	PASSWORD=developer
endif

DOMAIN_NAME=$(shell $(BASE)/scripts/getroutingsuffix)


# RHPDS but not on bastion
# Uncomment this block if you are deploying to RHPDS but are not running this
# on bastion (e.g. you are running this on your laptop).
#
# USERNAME refers to the OCP user that the demo is to be installed as, and
# PASSWORD is the password for that user. These variables are used in the
# "oc login" command.
#
#GUID=XXX-XXXX
#ON_RHPDS=1
#MASTER_NODE_URL=https://master.$(GUID).openshiftworkshop.com
#DOMAIN_NAME=apps.$(GUID).openshiftworkshop.com
#USERNAME=user1
#PASSWORD=openshift

# Set this if you need to install templates and quickstarts (if you are
# installing on OKD). This needs to be set to your credentials for
# registry.redhat.io.
#
REGISTRY_USERNAME=
REGISTRY_PASSWORD=


##################################################
# You should not need to change anything below   #
# this block.                                    #
##################################################

PROJ_TOOLS_NAME=$(PROJ_NAME_PREFIX)$(PROJ_TOOLS_SUFFIX)
PROJ_DEV_NAME=$(PROJ_NAME_PREFIX)$(PROJ_DEV_SUFFIX)
PROJ_TEST_NAME=$(PROJ_NAME_PREFIX)$(PROJ_TEST_SUFFIX)
PROJ_PROD_NAME=$(PROJ_NAME_PREFIX)$(PROJ_PROD_SUFFIX)

.PHONY: deployall clean deploytemplates printvariables login clean \
createprojects provisionroles deploygogs deploynexus deployjenkins preparedev \
preparetest prepareprod waitforgogspod clonenationalparks waitforjenkins \
createjenkinsjob waitfornexus configurenexus console gogs jenkins controller \
wsinfo healthz apiload apiall


deployall: printvariables deploytemplates login createprojects provisionroles \
deploygogs deploynexus deployjenkins createjenkinsjob preparedev preparetest \
prepareprod waitforgogspod clonenationalparks waitfornexus configurenexus
	@echo
	@echo "Deployment complete"


clean:
	@echo "Removing projects..."
	@$(BASE)/scripts/deleteproject $(PROJ_TOOLS_NAME)
	@$(BASE)/scripts/deleteproject $(PROJ_DEV_NAME)
	@$(BASE)/scripts/deleteproject $(PROJ_TEST_NAME)
	@$(BASE)/scripts/deleteproject $(PROJ_PROD_NAME)


deploytemplates:
	@if [ $(ON_RHPDS) -ne 1 ]; then \
	  if [ -z "$(REGISTRY_USERNAME)" -o -z "$(REGISTRY_PASSWORD)" ]; then \
	    echo "Error: You need to set the REGISTRY_USERNAME and REGISTRY_PASSWORD variables"; \
		exit 1; \
	  fi; \
	fi
	-@if [ $(ON_RHPDS) -eq 1 ]; then \
		echo "Running on RHPDS - do not need to install templates"; \
	else \
		echo "Not running on RHPDS - we need to install templates"; \
		oc login -u system:admin $(MASTER_NODE_URL); \
		oc create secret docker-registry imagestreamsecret \
		  --docker-username="$(REGISTRY_USERNAME)" \
		  --docker-password="$(REGISTRY_PASSWORD)" \
		  --docker-server=registry.redhat.io \
		  -n openshift \
		  --as system:admin; \
		oc create \
		  -f https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-persistent-template.json \
		  -n openshift; \
		oc create \
		  -f https://raw.githubusercontent.com/jboss-openshift/application-templates/ose-v1.4.16/openjdk/openjdk18-image-stream.json \
		  -n openshift; \
	fi


printvariables:
	@echo "The following information will be used to create the demo:"
	@echo
	@echo "ON_RHPDS = $(ON_RHPDS)"
	@echo "PROJ_NAME_PREFIX = $(PROJ_NAME_PREFIX)"
	@echo "PROJ_TOOLS_NAME = $(PROJ_TOOLS_NAME)"
	@echo "PROJ_DEV_NAME = $(PROJ_DEV_NAME)"
	@echo "PROJ_TEST_NAME = $(PROJ_TEST_NAME)"
	@echo "PROJ_PROD_NAME = $(PROJ_PROD_NAME)"
	@echo "NEXUS_SERVICE_NAME = $(NEXUS_SERVICE_NAME)"
	@echo "NATIONALPARKS_APPLICATION_NAME = $(NATIONALPARKS_APPLICATION_NAME)"
	@echo "PARKSMAP_APPLICATION_NAME = $(PARKSMAP_APPLICATION_NAME)"
	@echo "MASTER_NODE_URL = $(MASTER_NODE_URL)"
	@echo "USERNAME = $(USERNAME)"
	@echo "PASSWORD = $(PASSWORD)"
	@echo "DEMO_SCOPE = $(DEMO_SCOPE)"
	@echo "CREATE_TOOLS = $(CREATE_TOOLS)"
	@echo "CREATE_NATIONALPARKS = $(CREATE_NATIONALPARKS)"
	@echo "CREATE_PARKSMAP = $(CREATE_PARKSMAP)"
	@echo "CREATE_MLBPARKS = $(CREATE_MLBPARKS)"
	@echo "CREATE_ENVIRONMENT_PROJ = $(CREATE_ENVIRONMENT_PROJ)"
	@echo "GOGSUSER = $(GOGSUSER)"
	@echo "GOGSPASSWORD = $(GOGSPASSWORD)"
	@echo "DOMAIN_NAME = $(DOMAIN_NAME)"
	@echo
	@echo "Press enter to proceed"
	@read


login:
	@echo "Logging into OpenShift..."
	@oc login --insecure-skip-tls-verify -u $(USERNAME) -p $(PASSWORD) $(MASTER_NODE_URL)


createprojects:
	@if [ $(CREATE_TOOLS) -eq 1 ]; then \
	  echo "Creating tools project..."; \
	  oc new-project $(PROJ_TOOLS_NAME) --display-name="Tools"; \
	fi
	@if [ $(CREATE_ENVIRONMENT_PROJ) -eq 1 ]; then \
	  echo "Creating projects for environments..."; \
	  oc new-project $(PROJ_DEV_NAME) --display-name="Development Environment"; \
      oc new-project $(PROJ_TEST_NAME) --display-name="Test Environment"; \
      oc new-project $(PROJ_PROD_NAME) --display-name="Production Environment"; \
	fi


provisionroles:
	@echo "Provisioning roles..."
	@oc policy add-role-to-user edit system:serviceaccount:$(PROJ_TOOLS_NAME):jenkins -n $(PROJ_PROD_NAME)
	@oc policy add-role-to-user edit system:serviceaccount:$(PROJ_TOOLS_NAME):jenkins -n $(PROJ_TEST_NAME)
	@oc policy add-role-to-user edit system:serviceaccount:$(PROJ_TOOLS_NAME):jenkins -n $(PROJ_DEV_NAME)
	@oc policy add-role-to-user system:image-puller system:serviceaccount:$(PROJ_TEST_NAME):default -n $(PROJ_DEV_NAME)
	@oc policy add-role-to-user system:image-puller system:serviceaccount:$(PROJ_PROD_NAME):default -n $(PROJ_DEV_NAME)
	@oc policy add-role-to-user system:image-puller system:serviceaccount:$(PROJ_PROD_NAME):default -n $(PROJ_TEST_NAME)
	# parksmap-web requires view permission
	@oc policy add-role-to-user view system:serviceaccount:$(PROJ_DEV_NAME):default -n $(PROJ_DEV_NAME)
	@oc policy add-role-to-user view system:serviceaccount:$(PROJ_TEST_NAME):default -n $(PROJ_TEST_NAME)
	@oc policy add-role-to-user view system:serviceaccount:$(PROJ_PROD_NAME):default -n $(PROJ_PROD_NAME)


ifeq ($(CREATE_TOOLS), 1)
deploygogs:
	  @echo "Deploying gogs..."
	  @oc new-app -f https://raw.githubusercontent.com/chengkuangan/templates/master/gogs-persistent-template.yaml -p SKIP_TLS_VERIFY=true -n $(PROJ_TOOLS_NAME)

deploynexus:
	@echo "Deploying nexus..."
	@oc new-app -f https://raw.githubusercontent.com/chengkuangan/templates/master/nexus3-persistent-templates.yaml -n $(PROJ_TOOLS_NAME) -p NEXUS_REQUEST_MEM=3Gi -p NEXUS_LIMIT_MEM=4Gi

deploysonarqube:
	@echo "Deploying sonarqube..."
	@oc new-app -f $(BASE)/templates/sonarqube-persistent-templates.yaml -n $(PROJ_TOOLS_NAME)

deployjenkins:
	  @echo "Deploying Jenkins..."
	  @oc new-app jenkins-persistent \
	    -n $(PROJ_TOOLS_NAME) \
		-p MEMORY_LIMIT=3Gi
else
deploygogs:
	@echo "Not deploying gogs"

deploynexus:
	@echo "Not deploying nexus"

deploysonarqube:
	@echo "Not deploying sonarqube"

deployjenkins:
	@echo "Not deploying jenkins"
endif


createjenkinsjob:
	@echo "Create a working copy of Jenkins Job template xml file..."
	@cp $(BASE)/templates/jenkins-job.xml /tmp/jenkins-job-work.xml
	@echo "Update the jenkins template file with the actual demo environment settings..."
	@sed -i -e "s/https:\/\/github.com\/chengkuangan\/nationalparks.git/http:\/\/gogs:3000\/$(GOGSUSER)\/nationalparks.git/g" /tmp/jenkins-job-work.xml
	@sed -i -e "s/<name>demo1<\/name>/<name>$(GOGSUSER)<\/name>/g" /tmp/jenkins-job-work.xml
	@$(BASE)/scripts/jenkinsavailable $(PROJ_TOOLS_NAME)
	@echo "Create Jenkins job definition..."
	@oc rsh -n $(PROJ_TOOLS_NAME) dc/jenkins mkdir -p /var/lib/jenkins/jobs/nationalparks
	@oc cp -n $(PROJ_TOOLS_NAME) /tmp/jenkins-job-work.xml `oc get -n $(PROJ_TOOLS_NAME) pods -o custom-columns=:.metadata.name | grep jenkins | grep -v deploy`:/var/lib/jenkins/jobs/nationalparks/config.xml
	@rm -f /tmp/jenkins-job-work.xml


preparedev:
	@if [ $(CREATE_ENVIRONMENT_PROJ) -eq 1 ]; then \
	  echo "Preparing development environment..."; \
	  if [ $(CREATE_NATIONALPARKS) -eq 1 ]; then \
	    echo "Provisioning nationalparks..."; \
	    oc new-app -n $(PROJ_DEV_NAME) --allow-missing-imagestream-tags=true -f $(BASE)/templates/nationalparks-persistent-templates.yaml -p IMAGE_NAME=DevelopmentReady -p IMAGE_PROJECT_NAME=$(PROJ_DEV_NAME) -p APPLICATION_NAME=$(NATIONALPARKS_APPLICATION_NAME); \
        oc label service $(NATIONALPARKS_APPLICATION_NAME) type=parksmap-backend -n $(PROJ_DEV_NAME); \
	  fi; \
	  if [ $(CREATE_PARKSMAP) -eq 1 ]; then \
	    echo "Provisioning parksmap-web..."; \
		oc new-app -n $(PROJ_DEV_NAME) --allow-missing-imagestream-tags=true -f $(BASE)/templates/parksmap-web-dev-templates.yaml -p IMAGE_NAME=DevelopmentReady -p IMAGE_PROJECT_NAME=$(PROJ_DEV_NAME) -p APPLICATION_NAME=$(PARKSMAP_APPLICATION_NAME); \
	  fi; \
	fi


preparetest:
	@if [ $(CREATE_ENVIRONMENT_PROJ) -eq 1 ]; then \
	  echo "Preparing test environment..."; \
	  if [ $(CREATE_NATIONALPARKS) -eq 1 ]; then \
	    echo "Provisioning nationalparks..."; \
	    oc new-app -n $(PROJ_TEST_NAME) --allow-missing-imagestream-tags=true -f $(BASE)/templates/nationalparks-persistent-nobuild-templates.yaml -p IMAGE_NAME=TestReady -p IMAGE_PROJECT_NAME=$(PROJ_DEV_NAME); \
        oc label service $(NATIONALPARKS_APPLICATION_NAME) type=parksmap-backend -n $(PROJ_TEST_NAME); \
	  fi; \
	  if [ $(CREATE_PARKSMAP) -eq 1 ]; then \
	    echo "Provisioning parksmap-web..."; \
		oc new-app -n $(PROJ_TEST_NAME) --allow-missing-imagestream-tags=true -f $(BASE)/templates/parksmap-web-test-templates.yaml -p IMAGE_NAME=TestReady -p IMAGE_PROJECT_NAME=$(PROJ_DEV_NAME); \
	  fi; \
	fi


prepareprod:
	@if [ $(CREATE_ENVIRONMENT_PROJ) -eq 1 ]; then \
	  echo "Preparing production environment..."; \
	  if [ $(CREATE_NATIONALPARKS) -eq 1 ]; then \
	    echo "Provisioning nationalparks..."; \
	    oc new-app -n $(PROJ_PROD_NAME) --allow-missing-imagestream-tags=true -f $(BASE)/templates/nationalparks-prod-templates.yaml -p IMAGE_NAME=ProdReady -p IMAGE_PROJECT_NAME=$(PROJ_DEV_NAME) -p APPLICATION_NAME=$(PROD_NATIONALPARKS_SERVER_GREEN) -p PROD_ENV_VERSION="Green"; \
	    oc new-app -n $(PROJ_PROD_NAME) --allow-missing-imagestream-tags=true -f $(BASE)/templates/nationalparks-prod-templates.yaml -p IMAGE_NAME=ProdReady -p IMAGE_PROJECT_NAME=$(PROJ_DEV_NAME) -p APPLICATION_NAME=$(PROD_NATIONALPARKS_SERVER_BLUE) -p PROD_ENV_VERSION="Blue"; \
	    oc new-app -n $(PROJ_PROD_NAME) -f $(BASE)/templates/nationalparks-mongodb-prod-templates.yaml; \
		oc patch dc $(PROD_NATIONALPARKS_SERVER_GREEN) --patch "{\"spec\": { \"triggers\": []}}" -n $(PROJ_PROD_NAME); \
	    oc patch dc $(PROD_NATIONALPARKS_SERVER_BLUE) --patch "{\"spec\": { \"triggers\": []}}" -n $(PROJ_PROD_NAME); \
		oc set probe -n $(PROJ_PROD_NAME) dc/nationalparks-blue --liveness --readiness --get-url=http://:8080/ws/healthz/; \
		oc set probe -n $(PROJ_PROD_NAME) dc/nationalparks-green --liveness --readiness --get-url=http://:8080/ws/healthz/; \
	    oc expose svc/$(PROD_NATIONALPARKS_SERVER_GREEN) --name=nationalparks-bluegreen -n $(PROJ_PROD_NAME); \
	  fi; \
	  if [ $(CREATE_PARKSMAP) -eq 1 ]; then \
	    echo "Provisioning parksmap-web..."; \
	    oc new-app -n $(PROJ_PROD_NAME) --allow-missing-imagestream-tags=true -f $(BASE)/templates/nationalparks-prod-templates.yaml -p IMAGE_NAME=ProdReady -p IMAGE_PROJECT_NAME=$(PROJ_DEV_NAME) -p APPLICATION_NAME=$(PROD_PARKSMAP_SERVER_GREEN) -p PROD_ENV_VERSION="Green"; \
	    oc new-app -n $(PROJ_PROD_NAME) --allow-missing-imagestream-tags=true -f $(BASE)/templates/nationalparks-prod-templates.yaml -p IMAGE_NAME=ProdReady -p IMAGE_PROJECT_NAME=$(PROJ_DEV_NAME) -p APPLICATION_NAME=$(PROD_PARKSMAP_SERVER_BLUE) -p PROD_ENV_VERSION="Blue"; \
	    oc expose svc/${PROD_PARKSMAP_SERVER_GREEN} --name=parksmap-web-bluegreen -n $(PROJ_PROD_NAME); \
	  fi; \
	fi


waitforgogspod:
	@$(BASE)/scripts/waitforpod $(PROJ_TOOLS_NAME) gogs


creategogsuser:
	@echo "Creating gogs user..."
	@oc rsh -n $(PROJ_TOOLS_NAME) dc/gogs-postgresql /bin/sh -c 'LD_LIBRARY_PATH=/opt/rh/rh-postgresql95/root/usr/lib64 /opt/rh/rh-postgresql95/root/usr/bin/psql -U gogs -d gogs -c "INSERT INTO public.user (lower_name,name,email,passwd,rands,salt,max_repo_creation,avatar,avatar_email,num_repos) VALUES ('"'$(GOGSUSER)','$(GOGSUSER)','$(GOGSUSER)@gogs,com','40d76f42148716323d6b398f835438c7aec43f41f3ca1ea6e021192f993e1dc4acd95f36264ffe16812a954ba57492f4c107','konHCHTY7M','9XecGGR6cW',-1,'e4eba08430c43ef06e425e2e9b7a740f','$(GOGSUSER)@gogs.com',1"')"'


clonenationalparks: creategogsuser
	@$(BASE)/scripts/clonenationalparks $(PROJ_TOOLS_NAME) $(GOGSUSER) $(GOGSPASSWORD) "$(PROJ_NAME_PREFIX)" $(DOMAIN_NAME)


waitfornexus:
	@$(BASE)/scripts/waitforpod $(PROJ_TOOLS_NAME) nexus3


configurenexus:
	@$(BASE)/scripts/configurenexus $(PROJ_TOOLS_NAME)


console:
	$(eval URL="$(MASTER_NODE_URL)/console")
	@if [ "$(shell uname)" = "Darwin" ]; then \
	  open ${URL}; \
	else \
	  echo "${URL}"; \
	fi

gogs:
	$(eval URL="http://gogs-$(PROJ_TOOLS_NAME).$(DOMAIN_NAME)")
	@if [ "$(shell uname)" = "Darwin" ]; then \
	  open ${URL}; \
	else \
	  echo "${URL}"; \
	fi


jenkins:
	$(eval URL="https://jenkins-$(PROJ_TOOLS_NAME).$(DOMAIN_NAME)")
	@if [ "$(shell uname)" = "Darwin" ]; then \
	  open ${URL}; \
	else \
	  echo "${URL}"; \
	fi


controller:
	$(eval URL="http://gogs-$(PROJ_TOOLS_NAME).$(DOMAIN_NAME)/gogs/nationalparks/src/master/src/main/java/com/openshift/evg/roadshow/parks/rest/BackendController.java")
	@if [ "$(shell uname)" = "Darwin" ]; then \
	  open ${URL}; \
	else \
	  echo "${URL}"; \
	fi


wsinfo:
	@curl http://$(shell oc get -n $(PROJ_PROD_NAME) route/nationalparks-bluegreen --template='{{.spec.host}}')/ws/info/
	@echo


loop:
	@while true; do \
	  curl http://$(shell oc get -n $(PROJ_PROD_NAME) route/nationalparks-bluegreen --template='{{.spec.host}}')/ws/info/; \
	  echo; \
	  sleep 1; \
	done

healthz:
	@curl http://$(shell oc get -n $(PROJ_PROD_NAME) route/nationalparks-bluegreen --template='{{.spec.host}}')/ws/healthz/
	@echo


apiload:
	@curl http://$(shell oc get -n $(PROJ_PROD_NAME) route/nationalparks-bluegreen --template='{{.spec.host}}')/ws/data/load
	@echo


apiall:
	@curl http://$(shell oc get -n $(PROJ_PROD_NAME) route/nationalparks-bluegreen --template='{{.spec.host}}')/ws/data/all
	@echo