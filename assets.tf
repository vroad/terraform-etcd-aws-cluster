resource "random_string" "bucket_name_postfix" {
  count = module.this.enabled ? 1 : 0

  length  = 8
  special = false
}

module "assets_bucket" {
  source                    = "git::https://github.com/cloudposse/terraform-aws-s3-bucket.git?ref=0.25.0"
  acl                       = "private"
  enabled                   = module.this.enabled
  enable_glacier_transition = false
  versioning_enabled        = false
  name                      = "${module.this.id}-${random_string.bucket_name_postfix[0].result}"
  tags                      = module.this.tags
}


resource "aws_s3_bucket_object" "etcd-manager-assets" {
  for_each = module.this.enabled ? local.etcd_assets : {}

  bucket  = module.assets_bucket.bucket_id
  key     = each.key
  content = each.value
  etag    = md5(each.value)
}

resource "aws_s3_bucket_object" "cfssl" {
  count = module.this.enabled ? 1 : 0

  bucket = module.assets_bucket.bucket_id
  key    = "cfssl/cfssl"
  source = "${path.module}/cfssl/cfssl"
  etag   = filemd5("${path.module}/cfssl/cfssl")
}

resource "aws_s3_bucket_object" "cfssljson" {
  count = module.this.enabled ? 1 : 0

  bucket = module.assets_bucket.bucket_id
  key    = "cfssl/cfssljson"
  source = "${path.module}/cfssl/cfssljson"
  etag   = filemd5("${path.module}/cfssl/cfssljson")
}
