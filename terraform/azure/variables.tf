variable "location_name" {
  default = "West Europe"
}

variable "environment" {
  default = "Big Data Reference Lab"
}

variable "git_account_name" {
  type = string
}

variable "git_branch_name" {
  type = string
}

variable "git_repository_name" {
  type = string
}

variable "git_url" {
  type = string
}

variable "git_root_folder" {
  type = string
}

variable "git_root_synapse_folder" {
  type = string
}


variable "function_source_local_dir" {
  type = string
  default = "../../function/target/azure-functions/observation-generator"
}

variable "function_output_dir" {
  type = string
  default = "../../function.zip"
}