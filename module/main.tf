data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

module "instance_scheduler_namespace" {
  source = "terraform-ibm-modules/function/ibm//modules/namespace"

  name = var.scheduler_namespace_name
  action = (var.use_existing_namespace ? "get" : "create")
  description = "This namespace is used by the scheduler"
  resource_group_id = data.ibm_resource_group.resource_group.id
}

module "instance_scheduler_action" {
  source = "git::https://github.com/nven/vsi-operations-scheduler-solution//lib/terraform-ibm-action"

  inventories = var.inventories

  actions = {
    SchedulerVSIAction = {
      namespace = module.instance_scheduler_namespace.name
      action_repo_url = "https://github.com/nven/ansible-is-instance-actions"
      action_yml_map = {
        start = "start-vsi-playbook.yml"
        stop = "stop-vsi-playbook.yml"
      }
    }
  }

  depends_on = [module.instance_scheduler_namespace]

}

module "instance_scheduler_function" {
  source = "git::https://github.com/Cloud-Schematics/vsi-operations-scheduler-solution//lib/terraform-ibm-scheduler"

  schedules = {
    for k,s in var.schedules : 
    k => {
      namespace = module.instance_scheduler_namespace.name
      cron = s.cron
      action = "SchedulerVSIAction.${s.action}"
      env = s.env
      enabled = s.enabled
    }
  }

  depends_on = [module.instance_scheduler_action]

}

module "instance_scheduler_iam" {
  source = "./instance_scheduler_iam"

  iam_serviceid_name = module.instance_scheduler_namespace.name
  iam_access_policy = {
    schematics = {
        roles = [
            "Manager",
        ]
    }

    is = {
        roles = [
            "Editor",
        ]
    }

    resource_group = {
        roles = [
            "Viewer"
        ]
    }
  }
  ibmcloud_api_key = var.ibmcloud_api_key
  resource_group_id = data.ibm_resource_group.resource_group.id

  depends_on = [module.instance_scheduler_namespace]
}
