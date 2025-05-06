variable "private_subnet_ids" {
  default = ["subnet-0c09df98ebc8819fa","subnet-08a06698e71bfd3a6"]
  type        = list(string)
}

variable "vpc_id" {
  default = "vpc-063273428bad6e1f0"
  type    = string
}
variable "aws_secret_name" {
  default = "zpl-aurora-db-secret"
  type        = string
}
variable "aurora-sg" {
  default = "zpl-aurora-sg"
  type        = string
}
variable "aurora_cluster_name" {
  default =  "zpl-aurora-poc"
  type        = string
}
variable "aurora_instance_name" {
  default =  "zpl-aurora-instance"
  type        = string
}
