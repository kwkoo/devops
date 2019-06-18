BASE=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# Set this to 1 if running on RHPDS, 0 otherwise
ON_RHPDS=$(shell $(BASE)/scripts/onrhpds)

ifeq ($(ON_RHPDS), 1)
	MASTER_NODE_URL=$(shell $(BASE)/scripts/rhpdsmasterurl)
	USERNAME=user1
	PASSWORD=openshift
else
	MASTER_NODE_URL=https://localhost:8443
	USERNAME=developer
	PASSWORD=developer
endif

# t - create tools, n - create national parks, p - create parks map, m - create MLB parks
DEMO_SCOPE=tnmp

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

PROJ_NAME_PREFIX=gck-
PROJ_TOOLS_NAME=tools
PROJ_DEV_NAME=dev
PROJ_TEST_NAME=test
PROJ_PROD_NAME=prod
NEXUS_SERVICE_NAME=nexus3
NATIONALPARKS_APPLICATION_NAME=nationalparks
PARKSMAP_APPLICATION_NAME=parksmap-web

LOGOUT_WHEN_DONE=0

GOGSUSER=gogs
GOGSPASSWORD=gogs
JENKINS_USERNAME=jenkins
JENKINS_TOKEN=jenkins

PROJ_TOOLS_NAME=$(PROJ_NAME_PREFIX)tools
PROJ_DEV_NAME=$(PROJ_NAME_PREFIX)dev
PROJ_TEST_NAME=$(PROJ_NAME_PREFIX)test
PROJ_PROD_NAME=$(PROJ_NAME_PREFIX)prod

DOMAIN_NAME=$(shell $(BASE)/scripts/getroutingsuffix)



# Set this if you need to install templates and quickstarts.
#REGISTRY_USERNAME=
#REGISTRY_PASSWORD=

.PHONY: deployall clean deploytemplates printvariables login clean createprojects provisionroles deploygogs deploynexus deployjenkins preparedev preparetest prepareprod waitforgogspod clonenationalparks createjenkinsjob waitfornexus configurenexus


deployall: printvariables deploytemplates login createprojects provisionroles deploygogs deploynexus deployjenkins preparedev preparetest prepareprod waitforgogspod clonenationalparks createjenkinsjob waitfornexus configurenexus
	@echo "Done"

clean:
	@echo "Removing projects..."
	@$(BASE)/scripts/deleteproject $(PROJ_TOOLS_NAME)
	@$(BASE)/scripts/deleteproject $(PROJ_DEV_NAME)
	@$(BASE)/scripts/deleteproject $(PROJ_TEST_NAME)
	@$(BASE)/scripts/deleteproject $(PROJ_PROD_NAME)


deploytemplates:
	@if [ $(ON_RHPDS) -eq 1 ]; then \
		echo "Running on RHPDS - do not need to install default templates"; \
	else \
		echo "Not running on RHPDS - we need to install default templates"; \
		oc login -u system:admin $(MASTER_NODE_URL); \
		oc create secret docker-registry imagestreamsecret \
		  --docker-username="$(REGISTRY_USERNAME)" \
		  --docker-password="$(REGISTRY_PASSWORD)" \
		  --docker-server=registry.redhat.io \
		  -n openshift \
		  --as system:admin; \
		oc create \
		  -f https://raw.githubusercontent.com/openshift/library/master/official/java/templates/openjdk-web-basic-s2i.json \
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
	@echo "JENKINS_USERNAME = $(JENKINS_USERNAME)"
	@echo "JENKINS_TOKEN = $(JENKINS_TOKEN)"
	@echo "DOMAIN_NAME = $(DOMAIN_NAME)"
	@echo
	@sleep 5


login:
	@echo "Logging into OpenShift..."
	@oc login -u $(USERNAME) -p $(PASSWORD) $(MASTER_NODE_URL)


createprojects:
	ifeq ($(CREATE_TOOLS), 1)
	  @echo "Creating tools project..."
	  @oc new-project $(PROJ_TOOLS_NAME) --display-name="Tools"	
	endif
	ifeq ($(CREATE_ENVIRONMENT_PROJ), 1)
	  @echo "Creating projects for environments..."
	  @oc new-project $(PROJ_DEV_NAME) --display-name="Development Environment"
      @oc new-project $(PROJ_TEST_NAME) --display-name="Test Environment"
      @oc new-project $(PROJ_PROD_NAME) --display-name="Production Environment"
	endif


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


deploygogs:
	ifeq ($(CREATE_TOOLS), 1)
	  @echo "Deploying gogs..."
	  @oc new-app -f https://raw.githubusercontent.com/chengkuangan/templates/master/gogs-persistent-template.yaml -p SKIP_TLS_VERIFY=true -n $(PROJ_TOOLS_NAME)
	endif


deploynexus:
	ifeq ($(CREATE_TOOLS), 1)
	  @echo "Deploying nexus..."
	  @oc new-app -f https://raw.githubusercontent.com/chengkuangan/templates/master/nexus3-persistent-templates.yaml -n $(PROJ_TOOLS_NAME)
	endif


deploysonarqube:
	ifeq ($(CREATE_TOOLS), 1)
	  @echo "Deploying sonarqube..."
	  @oc new-app -f $(BASE)/templates/sonarqube-persistent-templates.yaml -n $(PROJ_TOOLS_NAME)
	endif


deployjenkins:
	ifeq ($(CREATE_TOOLS), 1)
	  @echo "Deploying Jenkins..."
	  @oc new-app jenkins-persistent -n $(PROJ_TOOLS_NAME)
	endif


preparedev:
	ifeq ($(CREATE_ENVIRONMENT_PROJ), 1)
	  @echo "Preparing development environment..."
	  ifeq ($(CREATE_NATIONALPARKS), 1)
	    @echo "Provisioning nationalparks..."
	    @oc new-app -n $(PROJ_DEV_NAME) --allow-missing-imagestream-tags=true -f $(BASE)/templates/nationalparks-persistent-templates.yaml -p IMAGE_NAME=DevelopmentReady -p IMAGE_PROJECT_NAME=$(PROJ_DEV_NAME) -p APPLICATION_NAME=$(NATIONALPARKS_APPLICATION_NAME)
        # label nationalparks as parksmap backend
        @oc label service $(NATIONALPARKS_APPLICATION_NAME) type=parksmap-backend -n $(PROJ_DEV_NAME)
	  endif
	  ifeq ($(CREATE_PARKSMAP), 1)
	    @echo "Provisioning parksmap-web..."
		@oc new-app -n $(PROJ_DEV_NAME) --allow-missing-imagestream-tags=true -f $(BASE)/templates/parksmap-web-dev-templates.yaml -p IMAGE_NAME=DevelopmentReady -p IMAGE_PROJECT_NAME=$(PROJ_DEV_NAME) -p APPLICATION_NAME=$(PARKSMAP_APPLICATION_NAME)
	  endif
	endif


preparetest:
	ifeq ($(CREATE_ENVIRONMENT_PROJ), 1)
	  @echo "Preparing test environment..."
	  ifeq ($(CREATE_NATIONALPARKS), 1)
	    @echo "Provisioning nationalparks..."
	    @oc new-app -n $(PROJ_TEST_NAME) --allow-missing-imagestream-tags=true -f $(BASE)/templates/nationalparks-persistent-nobuild-templates.yaml -p IMAGE_NAME=TestReady -p IMAGE_PROJECT_NAME=$(PROJ_DEV_NAME)
        # label nationalparks as parksmap backend
        @oc label service $(NATIONALPARKS_APPLICATION_NAME) type=parksmap-backend -n $(PROJ_TEST_NAME)
	  endif
	  ifeq ($(CREATE_PARKSMAP), 1)
	    @echo "Provisioning parksmap-web..."
		@oc new-app -n $(PROJ_TEST_NAME) --allow-missing-imagestream-tags=true -f $(BASE)/templates/parksmap-web-test-templates.yaml -p IMAGE_NAME=TestReady -p IMAGE_PROJECT_NAME=$(PROJ_DEV_NAME)
	  endif
	endif


prepareprod:
	ifeq ($(CREATE_ENVIRONMENT_PROJ), 1)
	  @echo "Preparing production environment..."
	  ifeq ($(CREATE_NATIONALPARKS), 1)
	    @echo "Provisioning nationalparks..."
	    PROD_NATIONALPARKS_SERVER_GREEN=nationalparks-green
	    PROD_NATIONALPARKS_SERVER_BLUE=nationalparks-blue
	    @oc new-app -n $(PROJ_PROD_NAME) --allow-missing-imagestream-tags=true -f $(BASE)/templates/nationalparks-prod-templates.yaml -p IMAGE_NAME=ProdReady -p IMAGE_PROJECT_NAME=$(PROJ_DEV_NAME) -p APPLICATION_NAME=$(PROD_NATIONALPARKS_SERVER_GREEN) -p PROD_ENV_VERSION="Green"
	    @oc new-app -n $(PROJ_PROD_NAME) --allow-missing-imagestream-tags=true -f $(BASE)/templates/nationalparks-prod-templates.yaml -p IMAGE_NAME=ProdReady -p IMAGE_PROJECT_NAME=$(PROJ_DEV_NAME) -p APPLICATION_NAME=$(PROD_NATIONALPARKS_SERVER_BLUE) -p PROD_ENV_VERSION="Blue"
	    @oc new-app -n $(PROJ_PROD_NAME) -f $(BASE)/templates/nationalparks-mongodb-prod-templates.yaml
		@oc patch dc $(PROD_NATIONALPARKS_SERVER_GREEN) --patch "{\"spec\": { \"triggers\": []}}" -n $(PROJ_PROD_NAME)
	    @oc patch dc $(PROD_NATIONALPARKS_SERVER_BLUE) --patch "{\"spec\": { \"triggers\": []}}" -n $(PROJ_PROD_NAME)
	    @oc expose svc/$(PROD_NATIONALPARKS_SERVER_GREEN) --name=nationalparks-bluegreen -n $(PROJ_PROD_NAME)
	  endif
	  ifeq ($(CREATE_PARKSMAP), 1)
	    @echo "Provisioning parksmap-web..."
		@PROD_PARKSMAP_SERVER_GREEN=parksmap-web-green
	    @PROD_PARKSMAP_SERVER_BLUE=parksmap-web-blue
	    @oc new-app -n $(PROJ_PROD_NAME) --allow-missing-imagestream-tags=true -f $(BASE)/templates/nationalparks-prod-templates.yaml -p IMAGE_NAME=ProdReady -p IMAGE_PROJECT_NAME=$(PROJ_DEV_NAME) -p APPLICATION_NAME=$(PROD_PARKSMAP_SERVER_GREEN)
	    @oc new-app -n $(PROJ_PROD_NAME) --allow-missing-imagestream-tags=true -f $(BASE)/templates/nationalparks-prod-templates.yaml -p IMAGE_NAME=ProdReady -p IMAGE_PROJECT_NAME=$(PROJ_DEV_NAME) -p APPLICATION_NAME=$(PROD_PARKSMAP_SERVER_BLUE)

	    @oc expose svc/$(PROD_PARKSMAP_SERVER_GREEN) --name=parksmap-web-bluegreen -n $(PROJ_PROD_NAME)
	  endif
	endif

waitforgogspod:
	@$(BASE)/scripts/waitforgogspod $(PROJ_TOOLS_NAME)

clonenationalparks:
	@$(BASE)/scripts/clonenationalparks $(PROJ_TOOLS_NAME) $(GOGSUSER) $(GOGSPASSWORD) $(PROJ_NAME_PREFIX) $(DOMAIN_NAME)

createjenkinsjob:
	@echo "Downloading the jenkins-cli.jar from the Jenkins Server..."
	@curl -k https://jenkins-$(PROJ_TOOLS_NAME).$(DOMAIN_NAME)/jnlpJars/jenkins-cli.jar --output /tmp/jenkins-cli.jar
	@echo "Create a working copy of Jenkins Job template xml file..."
	@cp $(BASE)/templates/jenkins-job.xml /tmp/jenkins-job-work.xml
	@echo "Update the jenkins template file with the actual demo environment settings..."
	sed -i -e "s/https:\/\/github.com\/chengkuangan\/nationalparks.git/http:\/\/gogs:3000\/$(GOGSUSER)\/nationalparks.git/g" /tmp/jenkins-job-work.xml
	sed -i -e "s/<name>demo1<\/name>/<name>$(GOGSUSER)<\/name>/g" /tmp/jenkins-job-work.xml
	@echo "Create Jenkins job definition..."
	java -jar /tmp/jenkins-cli.jar -s https://jenkins-$(PROJ_TOOLS_NAME).$(DOMAIN_NAME)/ -noCertificateCheck -auth $(JENKINS_USERNAME):$(JENKINS_TOKEN) create-job nationalparks < /tmp/jenkins-job-work.xml
	#rm -f /tmp/jenkins-job-work.xml

waitfornexus:
	@$(BASE)/scripts/waitfornexus $(PROJ_TOOLS_NAME)

configurenexus:
	@$(BASE)/scripts/configurenexus $(PROJ_TOOLS_NAME)
