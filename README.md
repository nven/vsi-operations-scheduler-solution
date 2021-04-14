# Overview

IBM Cloud Instance Scheduler Module - Design

![image](design/solution.png)

This module is used to Start/Stop VSI at the user provided schedule. 

The solution is built around the following IBM Cloud Services

* IBM Cloud Schematics - Ansible actions ( For Starting / Stoping VSI)
* IBM Cloud Functions ( For scheduling based on cron and invoking schematics to perform start/stop),
* IBM Cloud IAM ( To provide required permissions to the function's service id to access VSI and schematics)
* Terraform (Automate the scheduler setup in the users IBM cloud account).

And using the below software components

* Terraform IBM Modules - https://registry.terraform.io/namespaces/terraform-ibm-modules (Provision IBM Cloud resources - Function action, rule, triggers, IAM Policies, etc)
* Schematics Python SDK - https://github.com/IBM/schematics-python-sdk (Invoke schematics ansible action from IBM Function)

The user can provide the VSI IP list, Cron schedule and the action in the terraform configuration.

## Prerequisites

### IAM Permissions

* If you are a delegated user invited as part of a different account
  * Ensure the user account has the required permissions to create IBM Cloud Functions in the account.
  * Ensure the user account has permissions to create and change IAM policies in the account as this is required to provide access to the service id for IBM Cloud Schematics and IS services.
  * Ensure the user account has the required permission to create workspaces / actions(Manager)
  * Ensure the user account has the permissions to perform actions on the VSI(Editor)
  * The above permissions can be granted by the owner / administrator of the account
  
* If you are the account owner, No specifc steps are required to setup the permissions.

### Namespace Permissions

* If you are trying to setup the instance scheduler on a namespace created by a different user, 
  * Please review [this document](https://cloud.ibm.com/docs/openwhisk?topic=openwhisk-iam&locale=en#iam_namespace_policies) specific to IBM Cloud function access policy and ensure proper IAM policies has been setup for the user accessing the namespace
* If you have created the namespace, No specific steps are required to setup IAM policies

# Instance Scheduler Module Example

## Example Usage
```hcl
module "instance_scheduler" {
    source = "git::https://github.ibm.com/schematics-solution/terraform-ibm-instance-scheduler//module"

    inventories = var.inventories
    schedules = var.schedules

    ibmcloud_api_key = var.ibmcloud_api_key
    resource_group = var.resource_group
}
```
## Example input tfvars file
```hcl
ibmcloud_api_key=""

resource_group = "Default"

inventories = {
    dev = {
        instance_ip_list = [
            "10.240.64.4"
        ]
    }
}

schedules = {

    dev_7am_start_everyday = {
        cron = "0 7 * * *"
        action = "start"
        env = "dev"
        enabled = true
    }

    dev_11pm_stop_everyday = {
        cron = "0 23 * * *"
        action = "stop"
        env = "dev"
        enabled = true
    }
}
```


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Inputs

| Name                              | Description                                           | Type   | Default | Required |
|-----------------------------------|-------------------------------------------------------|--------|---------|----------|
| ibmcloud_api_key | API key of the user | string | n/a | yes |
| scheduler_namespace_name | Name of the instance scheduler namespace | string | instance_scheduler | no |
| use_existing_namespace | Option whether to create or use existing namespace | bool | false | no |
| resource_group | The name of the resource group under which the resources of the instance scheduler will be created | string | n/a | yes |
| inventories | User defined environment containing list of VSI ip's | map(object({<br>instance_ip_list = list(string)<br>})) |{ <br>&nbsp;dev = {<br>&nbsp;&nbsp;instance_ip_list = [<br>&nbsp;&nbsp;&nbsp;"\<ip 1\>",<br>&nbsp;&nbsp;&nbsp;"\<ip 2\>"<br>&nbsp;&nbsp;]<br>&nbsp;}<br> }| yes |
| schedules | User provided schedules with environment details and action to be performed|  map(object({<br>cron = string<br>action = start \| stop<br>env = string<br>enabled = bool<br>})) | {<br>&nbsp;start7am = {<br>&nbsp;&nbsp;cron = "0 7 * * *"<br>&nbsp;&nbsp;action = "start"<br>&nbsp;&nbsp;env = "dev"<br>&nbsp;&nbsp;enabled = true<br>&nbsp;&nbsp;}<br><br>&nbsp;stop11pm = {<br>&nbsp;&nbsp;cron = "0 23 * * *"<br>&nbsp;&nbsp;action = "stop"<br>&nbsp;&nbsp;env = "dev"<br>&nbsp;&nbsp;enabled = true<br>&nbsp;&nbsp;}<br>} | yes |

Notes

* `inventories` variable
  * This variable is used to define the environment / group the related hosts under one key. The key name defined can be user's choice For e.g dev, stage, prod, etc
* `schedules` variable
  * The `env` key should match one of the keys defined in the `inventories` variable 
  * The `cron` key should match the standard cron format `* * * * *`
  * The `action` key can be either `start` or `stop`
* The following privileges will be automatically provided to the service id created by the instance scheduler module
  | Service | Privilege | Purpose |
  |---------|-----------|----------|
  | Schematics | Manager | Required for creating schematics actions and jobs |
  | Infrastructure Services | Editor | Required for starting and stopping VSI's |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Usage - Command Line

terraform apply -var-file="input.tfvars"

## Usage - IBM Cloud Schematics Console

* Create a schematics workspace
* In the `Import your Terraform template` page, Enter the repo URL of the instance scheduler module
* Select Terraform version as terraform_v0.14
* Save template information
* Set the API Key
* Override the input variables as per your requirements and ensure you enter the values in `HCL2` format (The same format as used in tfvars variables)
* Generate / Apply Plan 

# Note

This module requires terraform version v0.14 and above as the module uses the latest features available as part of terraform v0.14