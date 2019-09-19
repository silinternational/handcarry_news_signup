variable "aws_region" {
  default = "us-east-1"
}

variable "app_name" {
  default = "wecarry-news-signup"
}

variable "web-memory" {
  default = "64"
}

variable "web-cpu" {
  default = "64"
}

variable "desired_count" {
  default = 2
}

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "cloudflare_email" {}
variable "cloudflare_token" {}
variable "cloudflare_domain" {}
variable "tf_remote_common" {}
variable "SENDGRID_API_KEY" {}
variable "SENDGRID_LIST_ID" {}

variable "subdomain" {
  default = "www"
}

variable "docker_tag" {
  default = "latest"
}
