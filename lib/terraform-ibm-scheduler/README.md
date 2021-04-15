# Scheduler Module Example

This module can be used to create a CRON based scheduler which executes schematics ansible actions at the defined schedules.

This module automatically sets up the following resources
* IBM Cloud function triggers (One trigger per the key defined in the schedules variable)
* IBM Cloud function rules (One rule per the key defined in the schedules variables execept when the enabled variable is set to false)


## Example Usage
```

module "myaction_module" {
  source = "git::https://github.ibm.com/schematics-solution/terraform-ibm-scheduler"

  actions = {
    SchedulerVSIAction = {
      namespace = "mynamespace"
      action_repo_url = "https://github.com/Cloud-Schematics/ansible-is-instance-actions"
      action_yml_map = {
        start = "start-vsi-playbook.yml"
        stop = "stop-vsi-playbook.yml"
      }
    }
  }

  inventories = {
      dev = {
          instance_ip_list = [
              "10.240.64.4"
          ]
      }
  }

}

module "scheduler_function" {
  source = "terraform-ibm-modules/Users/nvenkatesh/schematics/solutions/terraform-ibm-scheduler"

  schedules = {
    myschedule = {
      namespace = "mynamespace"
      cron = "* * * * *"
      action = "SchedulerVSIAction.start"
      env = "dev"
      enabled = "true | false"
    }
  }

  depends_on = [module.myaction_module]

}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Inputs

| Name                              | Description                                           | Type    | Default | Required |
|-----------------------------------|-------------------------------------------------------|--------|---------|----------|
| schedules | The details of the schedule | map(object({<br>&nbsp;&nbsp;&nbsp;&nbsp;namespace = string<br>&nbsp;&nbsp;&nbsp;&nbsp;cron = string<br>&nbsp;&nbsp;&nbsp;&nbsp;action = string (**Format** : \<actionkey\>.\<action\>)<br>&nbsp;&nbsp;&nbsp;&nbsp;env = string<br>&nbsp;&nbsp;&nbsp;&nbsp;enabled = bool<br>})) | n/a | yes |
| inventories | List of environments defined by the user | map(object({<br>&nbsp;&nbsp;&nbsp;&nbsp;instance_ip_list = list(string)<br>})) | n/a | yes |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->