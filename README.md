# multinode-terraform-terragrunt
Repository for multi-node terraform code with terragrunt on AWS cloud

## Methodology
- I am using [terraform](https://www.terraform.io/) and [terragrunt](https://terragrunt.gruntwork.io/) for expressing the infrastructure resources in AWS cloud.
- `terraform` is used to express resources in the cloud using its `aws` provider whereas `terragrunt` is being used to keep the `terraform` code clean and dry of configuration.
- I would be creating all resources, including VPC and subnets, routing and internet gateways, so that a dedicated, isolated environment can be established for the task.
- `terragrunt` allows a single click deployment of all terraform code, using `terragrunt run-all apply` that can detect changes in the `terragrunt` configuration and apply the diff.
- `terragrunt` allows code to be organised in a heirarchical manner so that resources can be organised.

## Prerequisites
__NOTE__: These instructions are for Linux
- `aws`: v2.0

    ```bash
    sudo apt install unzip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ```
- `terraform`: v1.3.0

    ```bash
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt-get update && sudo apt-get install terraform==1.3.0
    ```
- `terragrunt`: v0.39.1

    ```bash
    TERRAGRUNT_VERSION=0.39.1
    wget https://github.com/gruntwork-io/terragrunt/releases/download/v$TERRAGRUNT_VERSION/terragrunt_linux_amd64
    chmod +x terragrunt_linux_amd64
    mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
    ```

## Infrastructure deployment and testing
- Please configure your `aws` credentials by running `aws configure` after installing the cli utility.
- After that, please cd into the `terragrunt/` folder, and execute, `terragrunt run-all apply` command. `terragrunt` with the help of `terraform` would detect that the configuration was never applied and would print out a plan of deployment. Please enter `y` followed by enter to proceed. It will take few minutes for the entire deployment to be complete.
- EKS cluster will deployed. It will take a while to get done. Please pull the kubeconfig for the cluster using `aws eks update-kubeconfig --region <REGION> --name <CLUSTER_NAME>`. View and set your `kubectl` context for the cluster
```bash
kubectl config get-contexts
kubectl set-context <CONTEXT-NAME>
```
