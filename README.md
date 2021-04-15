<p align="justify">Cloud Operations is a set of process and practices used to operate or run a cloud environment.  The day-to-day cloud operations involves configuration management, resource reservation, resource allocation, resource rejuvenation, performance optimization, continuous compliance management, etc.  And, this is achieved by performing managed operations such as - start/stop, data backup, security scan, compliance policy checks, patch, upgrade, etc.   Typically, these managed operations are automated using Ansible playbooks; onboarded to IBM Cloud Schematics, as Schematics Actions – and made accessible to the Cloud Operator teams, who can perform these managed operations.</p>

<p align="justify">This solution illustrates an example cloud operation; using this solution you can save money by scheduling the stop and start of Virtual Machines in your account.  This solution can be suitably modified to perform other types of managed operation, in a scheduled manner.</p>

<p align="justify">The solution uses a combination of IBM Cloud Schematics (to perform the managed operation), and IBM Cloud Function (to automate the periodic triggers).  The following figure illustrates the components involved in the solution.</p>

![image](design/solution.png)

The solution is built using the following IBM Cloud Services
* IBM Cloud Schematics – to run the Ansible playbook to start / stop the VMs
* IBM Cloud Functions – as a scheduler (based on cron) to trigger the Schematics Action,
* IBM Cloud IAM – to provide required permissions to the Cloud Function's service-id to access VSI and schematics

In addition, it uses the following open-source software components
* Terraform IBM Modules - https://registry.terraform.io/namespaces/terraform-ibm-modules 
  * [terraform-ibm-function](https://github.com/terraform-ibm-modules/terraform-ibm-function) module 
  * [terraform-ibm-iam](https://github.com/terraform-ibm-modules/terraform-ibm-iam) module
* Schematics Python SDK - https://github.com/IBM/schematics-python-sdk 

The solution can be described in two parts:
* Part 1: Initialize - Setup the solution components (using Schematics)
	1. (optionally) Provision the VM 
  1. Provision the IBM Cloud Function, and configure the CRON triggers, based on a input schedule
*	Part 2: In steady state - Automate the managed operations
	1. Periodically, the Cloud Function will be triggered; which is configured to invoke a predefined Schematics Action (start or stop)
	2. Schematics Action, will use Ansible playbook to perform the VM start/stop operation

## Prerequisites

### IAM Permissions

* If you are the account owner, No specific steps are required to setup the permissions.
* If you are a delegated user, and invited to a different IBM Cloud account, ensure that the account owner / administrator has given you the following permissions, at the least:
  * to create IBM Cloud Functions in the account. [Administrator]
  * to create and update IAM policies in the account.
  * to create Schematics workspaces / actions [Manager]
  * to perform start / stop actions on the VM [Editor]

### Namespace Permissions

* If you have created the Cloud Function Namespace, No specific steps are required to setup IAM policies
* If you reusing an existing Cloud Function Namespace, that was created by a different user
  * Ensure that the account owner has defined proper IAM policies to provide access to the Namespace. Refer to [this document](https://cloud.ibm.com/docs/openwhisk?topic=openwhisk-iam&locale=en#iam_namespace_policies) for more details

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

* `inventories` 
  * This parameter is used to define the environment / group the related hosts under one key. The key name defined can be user's choice For e.g dev, stage, prod, etc.
* `schedules` 
  * The `env` key should match one of the keys defined in the `inventories` variable 
  * The `cron` key should match the standard cron format `* * * * *`
  * The `action` key can be either `start` or `stop`
* The following privileges will be automatically provided to the service-id created by the instance scheduler module
  | Service | Privilege | Purpose |
  |---------|-----------|----------|
  | Schematics | Manager | Required to create schematics actions and jobs |
  | Infrastructure Services | Editor | Required to start and stop VM's |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Example Usage
```hcl
module "instance_scheduler" {
    source = "git::https://github.ibm.com/schematics-solution/vsi-operations-scheduler-solution//module"

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