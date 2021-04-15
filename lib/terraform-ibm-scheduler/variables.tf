variable "schedules" {
  description = "Schedule details"
  type = map(object({
      namespace = string
      cron = string
      action = string
      env = string
      enabled = bool
    }
  ))
}
