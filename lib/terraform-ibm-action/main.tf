
module "scheduler_function_action" {
  source = "terraform-ibm-modules/function/ibm//modules/action"

  for_each = var.actions
  action_name = each.key
  namespace_name = each.value.namespace
  
  exec = [{
    main = "main"
    kind = "python:3.7"
    code_path = "${path.module}/schematics_actions.zip"
    code = null
    image = null
    components = null
    init = null
  }]

  limits = [{
    timeout = 300000
    log_size = null
    memory = null
  }]

  user_defined_parameters =  <<EOF
  [
    {
      "key" : "actions",
      "value" : ${jsonencode(var.actions)}
    },
    {
      "key" : "inventories",
      "value" : ${jsonencode(var.inventories)}
    }
  ]
  EOF
}
