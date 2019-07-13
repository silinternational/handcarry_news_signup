output "ecr_repo_url" {
  value = "${module.ecr.repo_url}"
}

output "url" {
  value = "https://${var.subdomain}.${var.cloudflare_domain}"
}
