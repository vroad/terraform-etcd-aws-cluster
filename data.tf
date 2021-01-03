data "aws_availability_zones" "all" {}

data "aws_s3_bucket" "backups" {
  bucket = var.backups_bucket
}

locals {
  availability_zones = var.aws_azs != null ? var.aws_azs : data.aws_availability_zones.all.names
}
