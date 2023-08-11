# Declarative Mutli-Stage Delivery

Keptn allows you to declaratively define multi-stage delivery workflows by defining `what needs to be done`. 
How to achieve this delivery workflow is then left to other components and also here Keptn provides deployment services, which allow you to set up a multi-stage delivery workflow without a single line of pipeline code.

The definition is manifested in a shipyard file that defines a task sequence for delivery

### Stages

A project stage (or just stage) defines a logical space (e.g., a namespace in Kubernetes), which has a dedicated purpose for an application in a continuous delivery process. Typically a project has multiple project stages that are ordered.*

    stages:
    - name: "dev"
        deployment_strategy: "direct"
        test_strategy: "functional"
    - name: "hardening"
        deployment_strategy: "blue_green_service"
        test_strategy: "performance"
    - name: "production"
        deployment_strategy: "blue_green_service"
        remediation_strategy: "automated"

### Keptn Bridge

The Keptn Bridge is a user interface that can be used to view and manage Keptn projects and services.

### Control Plane

The Keptn Control Plane runs the basic components that are required to run Keptn and to manage projects, stages, and services. This includes handling events and providing integration points. It orchestrates the task sequences that are defined in the shipyard but does not actively execute the tasks.

### Execution Plane

The Keptn Execution Plane hosts the Keptn-services that integrate the tools that are used to process the tasks.

### Service

Dans Keptn, un service correspond à une manière de gérer des microservices de notre application. Pour ce microservice, il est possible de définir des configurations (quelles tâches doit exécuter tel outil sur le microservice, de quelle manière)

# Steps

Image used for the tutorial

**ghcr.io/podtato-head/podtatoserver:v0.1.1**

1. Create a cluster (with kubernetes for example)
2. Install keptn (Controle Plane/Execution Plane) in the cluster via Helm (Helm Chart)
   
    `helm install keptn keptn -n keptn --create-namespace --wait \
  --version=1.0.0 --repo=https://charts.keptn.sh \
  --set=apiGatewayNginx.type=LoadBalancer`

1. Install keptn CLI to interact with keptn in the cluster 
    
    `curl -sL https://get.keptn.sh/ | bash`

    wget https://github.com/keptn/keptn/releases/download/1.0.0/keptn-1.0.0-linux-amd64.tar.gz && tar -xvzf keptn-1.0.0-linux-amd64.tar.gz && \
    sudo chmod +x keptn-1.0.0-linux-amd64 && sudo mv keptn-1.0.0-linux-amd64 /usr/local/bin

2. To have a better view of your keptn project, access the keptn bridge 
- First authenticate the keptn CLI and bridge against the keptn cluster (to access the cluster)
    
    `KEPTN_API_TOKEN=$(kubectl get secret keptn-api-token -n keptn \
    -ojsonpath={.data.keptn-api-token} | base64 --decode)`

    KEPTN_ENDPOINT=20.101.2.159:31600
    `keptn auth --endpoint=$KEPTN_ENDPOINT --api-token=KEPTN_API_TOKEN`

- Get the password 
    
    `kubectl get secret -n keptn bridge-credentials -o jsonpath="{.data.BASIC_AUTH_PASSWORD}" | base64 --decode`


## Create a service

We create a service called helloservice to handle the microservice we will deploy with helm

1. Create the job executor config file: it describe the tasks to be executed and how it will be 
   
Here is an exemple of the task deployment : which will deploy a microservice (or the app in this case) contained in the service helloservice

    apiVersion: v2
    actions:
    - name: "Deploy using helm"
        events:
        - name: "sh.keptn.event.deployment.triggered"
        tasks:
        - name: "Run helm"
            files:
             - /charts
            env:
            - name: IMAGE
               value: "$.data.configurationChange.values.image"
               valueFrom: event
            image: "alpine/helm:3.7.2"
            serviceAccount: "jes-deploy-using-helm"
            cmd: ["helm"]
            args: ["upgrade", "--create-namespace", "--install", "-n", "$(KEPTN_PROJECT)-$(KEPTN_STAGE)", "$(KEPTN_SERVICE)", "/keptn/charts/$(KEPTN_SERVICE).tgz", "--set", "image=$(IMAGE)", "--wait"]

    # use the following command to install the job-executor-service
# Add the relevant events here in a comma-separated list
    JES_VERSION="0.3.0"
    JES_NAMESPACE="keptn-jes"
    TASK_SUBSCRIPTION="sh.keptn.event.remote-task.triggered" 

    helm upgrade --install --create-namespace -n ${JES_NAMESPACE} \
        job-executor-service "https://github.com/keptn-contrib/job-executor-service/releases/download/${JES_VERSION}/job-executor-service-${JES_VERSION}.tgz" \
        --set remoteControlPlane.autoDetect.enabled="true",remoteControlPlane.topicSubscription="${TASK_SUBSCRIPTION}",remoteControlPlane.api.token="",remoteControlPlane.api.hostname="",remoteControlPlane.api.protocol=""
    
    kubectl apply -f ./job-executor/workloadClusterRoles.yaml

2. Add the job-executor as ressource to the service

    keptn add-resource --project=test-splunk --service=helloservice --all-stages --resource=./job-executor/job-executor-config.yaml --resourceUri=job/config.yaml


3. Add the ressources need for processing the tasks

    # Add the chart that contains the deployment and the kubernetes service against the microservice we wanna deploy and orcherstrate
    keptn add-resource --project=test-splunk --service=helloservice --all-stages --resource=./helloservice.tgz --resourceUri=charts/helloservice.tgz 
    # Add the ressources need for locust to do the test task
    keptn add-resource --project=test-splunk --service=helloservice --stage=qa --resource=./locust/basic.py
    keptn add-resource --project=test-splunk --service=helloservice --stage=qa --resource=./locust/locust.conf

4. We use locust to generate load

## Quality Evalutations with Prometheus

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

    helm install prometheus prometheus-community/prometheus \
        --namespace monitoring --create-namespace \
        --version 19.0.1

1. Installing Prometheus service
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

    helm install prometheus prometheus-community/prometheus \
        --namespace monitoring --create-namespace \
        --version 19.0.1
    helm upgrade --install -n keptn prometheus-service \
        https://github.com/keptn-contrib/prometheus-service/releases/download/0.9.1/prometheus-service-0.9.1.tgz \
        --reuse-values --set resources.requests.cpu=0m

2. Add the sli we need from prometheus and configure prometheus

    keptn add-resource --project=test-splunk --service=helloservice --stage=qa --resource=./prometheus/sli.yaml --resourceUri=prometheus/sli.yaml
    keptn configure monitoring prometheus --project=test-splunk --service=helloservice

keptn add-resource --project=test-splunk --service=helloservice --stage=qa --resource=./sli.yaml --resourceUri=sli.yaml
3. Add the slo for the quality gate for stage qa

    keptn add-resource --project=test-splunk --service=helloservice --stage=qa --resource=./slo.yaml --resourceUri=slo.yaml

## Release validation

# Adding Locust files to production stage          
# Add the ressources need for locust to do the test task


    kubectl apply -f ./job-executor/workloadClusterRoles.yaml 

    keptn add-resource --project=test-splunk --service=helloservice --all-stages --resource=./job-executor/job-executor-config.yaml --resourceUri=job/config.yaml

    keptn add-resource --project=test-splunk --service=helloservice --all-stages --resource=./helloservice.tgz --resourceUri=charts/helloservice.tgz 

    keptn add-resource --project=test-splunk --service=helloservice --all-stages --resource=./locust/basic.py
    keptn add-resource --project=test-splunk --service=helloservice --all-stages --resource=./locust/locust.conf

    
    keptn add-resource --project=test-splunk --service=helloservice --all-stages --resource=./prometheus/sli.yaml --resourceUri=prometheus/sli.yaml
    
    keptn add-resource --project=test-splunk --service=helloservice --all-stages --resource=./slo.yaml --resourceUri=slo.yaml

    
    
ghcr.io/podtato-head/podtatoserver:v0.1.1

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