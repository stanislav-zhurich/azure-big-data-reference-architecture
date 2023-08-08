variable "location_name" {
  default = "West Europe"
}

variable "environment" {
  default = "Big Data Reference Lab"
}

variable "data_factory_github_config" {
  type = object({
    account_name = string,
    branch_name = string,
    repository_name = string,
    root_folder = string,
    git_url = string
  })
  default = {
    account_name = "stanislav-zhurich"
    branch_name = "main"
    repository_name = "azure-big-data-reference-architecture"
    root_folder = "/datafactory"
    git_url = "https://github.com"
  }
}


variable "function_source_local_dir" {
  type = string
  default = "../../function/target/azure-functions/observation-generator"
}

variable "function_output_dir" {
  type = string
  default = "../../function.zip"
}