# Terraform using azure DevOps

## 1.VS code and azure Repo Task

1. Create one repo in azure repo with gitignore terraform
2. Create one terraform.tf  in vs code
3. Then perform the following action on tf file in vs code 
   * git init
   * git remote add origin https://devops0329@dev.azure.com/devops0329/project-new-1/_git/create-vm-terraform
   * git add .
   * git push origin master 

```main.tf
terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "=2.46.0"
    }
  }
  #backend "azurerm" {
  #  resource_group_name = "tfstate"
  #  storage_account_name = "tfstate9802"
  #  container_name = "tfstate"
  #  key = "terraform.tfstate"
  #}
}

provider "azurerm" {
  features {}
 # subscription_id = "3e53b3eb-60c4-43ab-b236-bc0cef419fe2"
 # client_id       = "f7949458-7404-4c07-8ab8-1ecba7f70924"
 # client_secret   = "TWR8Q~JfIeEn5E3CfsAdTQVKZ.2FE8MSLoOw5bX3"
 # tenant_id       = "8732780d-dfeb-4c43-b551-b20e137b33cf"
 # }

resource "azurerm_resource_group" "rg" {
    name = "store-rg"
    location = "East US"
}

resource "azurerm_storage_account" "stacc" {
    name                     = "devenstacc"
    resource_group_name      = azurerm_resource_group.rg.name
    location                 = azurerm_resource_group.rg.location
    account_tier            = "Standard"
    account_replication_type = "GRS"

    tags = {
        environment = "dev"
    }
}
```

## 2.Create storage account to store tfstate file

Prerequisite: Run az login

Use the following script to create storage account in azure  

```SHELL SCRIPT

#!/bin/bash
RESOURCE_GROUP_NAME=tfstate
STORAGE_ACCOUNT_NAME=tfstate$RANDOM
CONTAINER_NAME=tfstate
# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location eastus
# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob
# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME


```

## 3.Add terraform extension to the azure devops organization

1. Click on organization setting
2. Then click on extension
3. Browse marketplace 
4. Search terraform and select the official extension

## 4.Create 2 service principal

### NOTE : One service connection for the tfstate storage account 
###        Second service connection for the resource that we are creating

1. While creating the service principal for the tfstate storage account we must select the exact resource group
   the is already created
2. While creating the service principal for the resource that we are creating don't select any resource group


## 5.Create YAML pipeline 

```YAML

trigger: none

pool:
  vmImage: ubuntu-latest

stages:
  - stage: tfvalidate
    jobs:
      - job: validate
        continueOnError: false
        steps:
        - task: TerraformInstaller@1
          displayName: tfinstall
          inputs:
            terraformVersion: 'latest'

       # - task: AzureCLI@2
       #   inputs:
       #     azureSubscription: 'DevTest'
       #     scriptType: 'bash'
       #     scriptLocation: 'inlineScript'
       #     inlineScript: |
       #      az --version
       #       az account show
        - task: TerraformTaskV4@4
          displayName: tfinit
          inputs:
            provider: 'azurerm'
            command: 'init'
            backendServiceArm: 'DevTest'
            backendAzureRmResourceGroupName: 'tfstate'
            backendAzureRmStorageAccountName: 'tfstate9802'
            backendAzureRmContainerName: 'tfstate'
            backendAzureRmKey: 'terraform.tfstate'
            
        - task: TerraformTaskV4@4
          displayName: tfvalidate
          inputs:
            provider: 'azurerm'
            command: 'validate'

  - stage: tfdeploy
    condition: succeeded('tfvalidate')
    dependsOn: tfvalidate
    jobs:
      - job: apply
        steps:
          - task: TerraformInstaller@1
            displayName: tfinstall
            inputs:
              terraformVersion: 'latest'
              
          - task: TerraformTaskV4@4
            displayName: ftinit
            inputs:
              provider: 'azurerm'
              command: 'init'
              backendServiceArm: 'DevTest'
              backendAzureRmResourceGroupName: 'tfstate'
              backendAzureRmStorageAccountName: 'tfstate9802'
              backendAzureRmContainerName: 'tfstate'
              backendAzureRmKey: 'terraform.tfstate'

          - task: TerraformTaskV4@4
            displayName: tfplan
            inputs:
              provider: 'azurerm'
              command: 'plan'
              environmentServiceNameAzureRM: 'DevTestSample'
              
          - task: TerraformTaskV4@4
            displayName: tfapply
            inputs:
              provider: 'azurerm'
              command: 'apply'
              environmentServiceNameAzureRM: 'DevTestSample'

```

### NOTE : For the backend rm storage attach the service principal for the tfstate storage account

### NOTE : FOr plan and apply stage attacch the service principal for the resource that we are going to create

Complete
