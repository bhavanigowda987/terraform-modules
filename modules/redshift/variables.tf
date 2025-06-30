variable "cluster_identifier" {}
variable "node_type" {}
variable "number_of_nodes" {}
variable "database_name" {}
variable "master_username" {}
variable "master_password" {
  sensitive = true
}
variable "vpc_id" {}
variable "subnet_ids" {
  type = list(string)
}
variable "allowed_ips" {
  type = list(string)
}
variable "log_bucket_name" {}

