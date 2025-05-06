variable "upload_bucket" {
  default = "cmm-upload-bucket"
  type        = string
}
variable "download_bucket" {
  default = "cmm-download-bucket"
  type        = string
}
variable "app_data_bucket" {
  default =  "cmm-app-data-bucket"
  type        = string
}
variable "s3_access_role" {
  default = "zpl_s3_access_role"
  type        = string
}
variable "s3_policy" {
  default =  "zpl_s3_policy"
  type        = string
}
