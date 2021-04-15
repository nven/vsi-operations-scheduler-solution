# Action Module Example

This module is used to create IBM Cloud function action which will invoke IBM Cloud schematics service API to create ansible action and jobs and to define the details of schematics actions such as repo details, supported action names mapped to the ansible actions yaml and inventories to define and group the user's environment.

The module sets up the following resources automatically

* IBM Cloud function action (One action per the key defined under actions variable)
* IBM Cloud Schematics action (During action runtime, One action is created per environment so that all the schematics jobs related to the same environment are executed under the same schematics action)


## Example Usage
```

module "myaction_module" {
  source = "git::https://github.ibm.com/schematics-solution/terraform-ibm-action"

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

```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Inputs

| Name                              | Description                                           | Type   | Default | Required |
|-----------------------------------|-------------------------------------------------------|--------|---------|----------|
| actions | The details of the action | map(object({namespace = string<br>action_repo_url = string<br>action_yml_map = map(string)<br>}<br>)) | n/a | yes |
| inventories | User defined environment containing list of VSI ip's | map(object({<br>instance_ip_list = list(string)<br>})) | n/a | yes |


## Outputs

| Name | Description |
|------|-------------|
| actions | List of defined actions |

## Note

* IBM Cloud Function and Schematics action names are based on the key names defined in the `actions` map
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->