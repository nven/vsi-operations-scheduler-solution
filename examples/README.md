# Instance Scheduler Module Example

This example illustrates how to use the `instance_scheduler` module.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Inputs

| Name                              | Description                                           | Type   | Default | Required |
|-----------------------------------|-------------------------------------------------------|--------|---------|----------|
| ibmcloud_api_key | API key of the user | string | n/a | yes |
| scheduler_namespace_name | Name of the instance scheduler namespace | string | instance_scheduler | no |
| use_existing_namespace | Option whether to create or use existing namespace | bool | false | no |
| resource_group | The name of the resource group under which the resources of the instance scheduler will be created | string | Default | no |
| inventories | User defined environment containing list of VSI ip's | map(object({<br>instance_ip_list = list(string)<br>})) |{ <br>&nbsp;dev = {<br>&nbsp;&nbsp;instance_ip_list = [<br>&nbsp;&nbsp;&nbsp;"10.240.64.4"<br>&nbsp;&nbsp;]<br>&nbsp;}<br> }| yes |
| schedules | User provided schedules with environment details and action to be performed|  map(object({<br>cron = string<br>action = start \| stop<br>env = string<br>enabled = bool<br>})) | {<br>&nbsp;dev_7am_start_everyday = {<br>&nbsp;&nbsp;cron = "0 7 * * *"<br>&nbsp;&nbsp;action = "start"<br>&nbsp;&nbsp;env = "dev"<br>&nbsp;&nbsp;enabled = true<br>&nbsp;&nbsp;}<br><br>&nbsp;dev_11pm_stop_everyday = {<br>&nbsp;&nbsp;cron = "0 23 * * *"<br>&nbsp;&nbsp;action = "stop"<br>&nbsp;&nbsp;env = "dev"<br>&nbsp;&nbsp;enabled = true<br>&nbsp;&nbsp;}<br>} | yes |

Notes

* `inventories` variable
  * This variable is used to define the environment / group the related hosts under one key. The key name defined can be user's choice For e.g dev, stage, prod, etc
* `schedules` variable
  * The `env` key should match one of the keys defined in the `env` variable 
  * The `cron` key should match the standard cron format `* * * * *`
  * The `action` key can be either `start` or `stop`


<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Usage - Command Line

terraform apply -var-file="input.tfvars"

## Usage - IBM Cloud Schematics Console

* Create a schematics workspace
* In the `Import your Terraform template` page, Enter the repo URL of this example https://github.com/Cloud-Schematics/vsi-operations-scheduler-solution/tree/master/examples
* Select Terraform version as terraform_v0.14
* Save template information
* Set the API Key
* Override the input variables as per your requirements and ensure you enter the values in `HCL2` format (The same format as used in tfvars variables)
* Generate / Apply Plan 

## Note

This module requires terraform version v0.14 and above as the module uses the latest features available as part of terraform v0.14