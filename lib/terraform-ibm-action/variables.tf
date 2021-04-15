variable "actions" {
  description = "Action details"
  type = map(object({
      namespace = string
      action_repo_url = string
      action_yml_map = map(string)
    }
  ))
}

variable "inventories" {
  description = "User environment details with IP list"
  type = map(object({
    instance_ip_list = list(string)
  }))
}