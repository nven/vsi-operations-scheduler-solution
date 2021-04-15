module "scheduler_function_trigger" {
  source = "terraform-ibm-modules/function/ibm//modules/trigger"

  for_each = var.schedules

  trigger_name = "scheduler_trigger_${each.key}"
  namespace_name = each.value.namespace
  feed = [{
    name = "/whisk.system/alarms/alarm"
    parameters = <<EOF
    [
      {
        "key":"cron",
        "value":"${each.value.cron}"
      }
    ]
    EOF
  }]
  user_defined_parameters =  <<EOF
  [
    {
      "key" : "action",
      "value" : "${each.value.action}"
    },
    {
      "key" : "env_name",
      "value" : "${each.value.env}"
    }
  ]
  EOF

}

module "scheduler_function_rules" {
  source = "terraform-ibm-modules/function/ibm//modules/rule"

  for_each = {
    for k,s in var.schedules : k => s if s.enabled == true
  }

  rule_name = "scheduler_rule_${each.key}"
  namespace_name = each.value.namespace
  action_name = split(".", each.value.action)[0]
  trigger_name = "scheduler_trigger_${each.key}"
  
  depends_on = [module.scheduler_function_trigger]
}
