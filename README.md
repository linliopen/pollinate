# Pollinate

## Principles of Continue Delivery
* Everything should be version control
* Everything should be as code
* Everything should be automatically

So as long as you change code, it will trigger one of pipeline's execution.


## Codebase Category 
Normally, a software system combined with many complexities. We put them to several codebase by CD domain category.

* business code: such as backend or frontend code.
* build code: describe how to build business code. Every business codebase should include a build code at least. 
  And every build code must output an artifact with a unique version. The artifact will be store in Nexus or a private docker registry.
* config code: Every config codebase treat as a business codebase that it will be store in Nexus like an artifact. 
  And every environment have a config codebase.
* deployment code: describe how to deploy artifact to Dev/Staging/Prod environment.
* sql code: version control sql code is important as business code.


## Structures of This Codebase
It would be many repos created if we follow codebase's category above. So, we put them in a codebase.

The structure of this codebase as below:

* business: contains business's logic.
* config: split every environment configs as a subfolder. 
* .github: contains build pipelines and deployment pipelines base GitHub Actions.
* infra: contains code for creating infrastructure. 
* sql-migration: version control sql

## Create Infrastructure by Terraform
1. create a VM and a MySQL Server:

   1. run `cd infra/terraform`
   1. run `terraform init`
   1. run `terraform plan -var-file ../../config/test/terraform.tfvars -out=.`
   1. run `terraform apply`
   1. upload terraform's output file to AWS's3 which was generated from step above.

2. Initial Application's Runtime Environment In VM:

   1. download terraform's output file from AWS's3 to `infra/ansible`
   1. run `cd infra/ansible`
   1. run `ansible-playbook -i inventory playbook.yaml`
   
P.S. It's would be better splitting the code of infrastructure to another codebase.


## Build Business Codebase

   1. setup Maven and Docker environment at you laptop.
   1. run `cd business/ && mvn clean package` to build Java code.
   1. run `docker login example.org/registry -u user` to login private docker registry.
   1. run `docker build -t example.org/registry/pollinate:v1.0 .` to build docker image.
   1. run `docker push example.org/registry/pollinate:v1.0` to push docker image to private docker registry.

   
## Setup Build Pipeline
Any changes of code will trigger build pipeline's execution. 

Every codebase should include a building pipeline which in .github/workflows named build.yml.

The step's detail of build pipeline described in .github/workflows/build.yml


## Setup Deployment pipeline
After build pipeline, a docker image must be uploaded to an artifact's manager like docker-harbor. 

Now we can deploy docker image to dev environment by ansible. The code is in .github/workflows/ansible-deploy-app-dev.yaml.









