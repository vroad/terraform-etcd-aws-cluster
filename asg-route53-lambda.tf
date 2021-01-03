module "asg-route53-lambda" {
  source = "git::git@github.com:yolo-japan/asg-route53-lambda-terraform.git?ref=5c17220506b3146d159ba3e2cce8e64b2c31aaf2"

  enabled = module.this.enabled
  name    = module.this.id
}
