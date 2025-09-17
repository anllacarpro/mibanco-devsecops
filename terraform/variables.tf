variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "project_name" {
  type    = string
  default = "mibanco-devsecops"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "node_size" {
  type    = string
  default = "Standard_B2s"
}

variable "image_tag" {
  type    = string
  default = "latest" # Git SHA is passed from CI
}

variable "github_owner" {
  type    = string
  default = null
}

variable "github_repo" {
  type    = string
  default = null
}

variable "github_token" {
  type    = string
  default = null
}
