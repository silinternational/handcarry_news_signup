/*
 * Create ECR repo
 */
module "ecr" {
  source              = "github.com/silinternational/terraform-modules//aws/ecr?ref=2.6.0"
  repo_name           = "${var.app_name}-${data.terraform_remote_state.common.app_env}"
  ecsInstanceRole_arn = "${data.terraform_remote_state.common.ecsInstanceRole_arn}"
  ecsServiceRole_arn  = "${data.terraform_remote_state.common.ecsServiceRole_arn}"
  cd_user_arn         = "${data.terraform_remote_state.common.codeship_arn}"
}

/*
 * Create target group for ALB
 */
resource "aws_alb_target_group" "tg" {
  name                 = "${replace("tg-${var.app_name}-${data.terraform_remote_state.common.app_env}", "/(.{0,32})(.*)/", "$1")}"
  port                 = "3000"
  protocol             = "HTTP"
  vpc_id               = "${data.terraform_remote_state.common.vpc_id}"
  deregistration_delay = "30"

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    path    = "/"
    matcher = "200"
  }
}

/*
 * Create listener rule for hostname routing to new target group
 */
resource "aws_alb_listener_rule" "tg" {
  listener_arn = "${data.terraform_remote_state.common.alb_https_listener_arn}"
  priority     = "227"

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.tg.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${var.subdomain}.${var.cloudflare_domain}"]
  }
}

resource "aws_cloudwatch_log_group" "handcarry" {
  name              = "${var.app_name}-${data.terraform_remote_state.common.app_env}"
  retention_in_days = 14

  tags {
    app_name = "${var.app_name}"
    app_env  = "${data.terraform_remote_state.common.app_env}"
  }
}

/*
 * Create task definition template
 */
data "template_file" "task_def_web" {
  template = "${file("${path.module}/task-def-web.json")}"

  vars {
    cpu               = "${var.web-cpu}"
    memory            = "${var.web-memory}"
    docker_image      = "${module.ecr.repo_url}"
    docker_tag        = "${var.docker_tag}"
    log_group         = "${aws_cloudwatch_log_group.handcarry.name}"
    region            = "${var.aws_region}"
    log_stream_prefix = "${var.app_name}-${data.terraform_remote_state.common.app_env}"
    SENDGRID_API_KEY  = "${var.SENDGRID_API_KEY}"
    SENDGRID_LIST_ID  = "${var.SENDGRID_LIST_ID}"
  }
}

/*
 * Create new ecs service
 */
module "ecsweb" {
  source             = "github.com/silinternational/terraform-modules//aws/ecs/service-only?ref=2.6.0"
  cluster_id         = "${data.terraform_remote_state.common.ecs_cluster_id}"
  service_name       = "${var.app_name}"
  service_env        = "${data.terraform_remote_state.common.app_env}"
  container_def_json = "${data.template_file.task_def_web.rendered}"
  desired_count      = "${var.desired_count}"
  tg_arn             = "${aws_alb_target_group.tg.arn}"
  lb_container_name  = "web"
  lb_container_port  = "3000"
  ecsServiceRole_arn = "${data.terraform_remote_state.common.ecsServiceRole_arn}"
}

/*
 * Create Cloudflare DNS record
 */
resource "cloudflare_record" "dns" {
  domain  = "${var.cloudflare_domain}"
  name    = "${var.subdomain}"
  value   = "${data.terraform_remote_state.common.alb_dns_name}"
  type    = "CNAME"
  proxied = true
}
