# Servian Technical Challenge

## Pre-requisites:

1. Terraform version 1.1.9
2. aws cli v2.3.5
3. Bash shell
4. Newly created AWS cloud account (might still work even if default vpc has been deleted)
5. An admin user account with Administrative privileges

## To deploy the app:
1. Configure your aws cli to get your credentials stored. Use the profile that's got administrator privileges
2. In the root folder, run `terraform apply -auto-approve`
3. Of the deployment succeeded, A link to the app will be shown in the cli at the very end

### Architecture

* Fargate over EC2 to deploy the application. Don't have to manage scaling, and the app is simple enough
* RDS over EC2 for the database. Again to avoid managing a server
* Used the default VPC and created security groups that allowed all traffic to go to the web app, listening to just the HTTP port
* Points of improvements:
  * create a separate VPC
  * VPC can n-tier and distribute the database and web app
  * Security can be improved by avoiding a star/asterisk value on the iam policies

### CICD

* There's not much CICD implemented with this project. Just purely IaC
* Basic CIwould be to use CircleCI or Codebuild, store the secrets in a Secrets Manager, and run terraform from there. The build will be triggered when a push to master happens. Another environment (aws account) can be created for testing. A Gate of manual approval lies between the dev environment and the prod environment. If there are no regression bugs, then the deployment can be approved to prod.

Please reach out to j.tabacii@gmail.com for any feedback from this project.

Cheers!

-jon
