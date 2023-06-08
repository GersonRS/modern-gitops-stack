variable "metrics_storage" {
  description = "MinIO S3 bucket configuration values for the bucket where the archived metrics will be stored."
  type = object({
    bucket     = string
    endpoint   = string
    access_key = string
    secret_key = string
    insecure   = optional(bool, false)
  })
  default = null
}