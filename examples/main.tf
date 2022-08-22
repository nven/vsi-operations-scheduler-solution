provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
}

module "instance_scheduler" {
    source = "../module"

    ibmcloud_api_key = var.ibmcloud_api_key

    resource_group = var.resource_group
    scheduler_namespace_name = var.scheduler_namespace_name
    use_existing_namespace = var.use_existing_namespace
    
    inventories = var.inventories
    schedules = var.schedules

}
