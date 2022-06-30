data "ibm_iam_service_id" "solution_service_id" {
  name = var.iam_serviceid_name
}

resource "null_resource" "unlock_service_id" {
  triggers = {
    ibmcloud_api_key = var.ibmcloud_api_key
    service_id = data.ibm_iam_service_id.solution_service_id.service_ids[0].id
  }

  provisioner "local-exec" {
      when = create
      command = "./unlock_service_id.sh ${self.triggers.ibmcloud_api_key} ${self.triggers.service_id}"
      working_dir = path.module
  }

}

module "solutions_iam_service_policy" {
  source = "terraform-ibm-modules/iam/ibm//modules/service-policy"
  version = "1.0.1"

  for_each = var.iam_access_policy

  iam_service_id = data.ibm_iam_service_id.solution_service_id.service_ids[0].id
  roles = each.value.roles
  resources = [{
      service = ( each.key != "resource_group" ? each.key : null )
      region = null
      attributes = null
      resource_group_id = null
      resource = ( each.key != "resource_group" ? null : var.resource_group_id )
      resource_type = ( each.key != "resource_group" ? null : "resource-group" )
      resource_instance_id = null
    },
  ]
  account_management = null

  depends_on = [null_resource.unlock_service_id]
}

resource "null_resource" "relock_service_id" {

  triggers = {
    ibmcloud_api_key = var.ibmcloud_api_key
    service_id = data.ibm_iam_service_id.solution_service_id.service_ids[0].id
  }

  provisioner "local-exec" {
      command = "./relock_service_id.sh ${self.triggers.ibmcloud_api_key} ${self.triggers.service_id}"
      working_dir = path.module
  }

  provisioner "local-exec" {
      when = destroy
      command = "./unlock_service_id.sh ${self.triggers.ibmcloud_api_key} ${self.triggers.service_id}"
      working_dir = path.module
  }

  depends_on = [module.solutions_iam_service_policy]
}
