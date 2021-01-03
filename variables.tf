variable "flatcar_ami_id" {
  type = string
}

variable "aws_azs" {
  type    = list(string)
  default = null
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "disk_type" {
  type    = string
  default = "gp3"
}

variable "disk_size" {
  type    = number
  default = 8
}

variable "disk_iops" {
  type    = number
  default = null
}

variable "disk_throughput" {
  type    = number
  default = null
}

variable "on_demand_percentage_above_base_capacity" {
  type    = number
  default = 0
}

variable "spot_allocation_strategy" {
  type    = string
  default = "lowest-price"
}

variable "instance_types" {
  type    = set(string)
  default = ["t3.small", "t3a.small"]
}

variable "capacity_rebalance" {
  type    = bool
  default = false
}

variable "backups_bucket" {
  type = string
}

variable "dns_zone_id" {
  type = string
}

variable "dns_zone" {
  type = string
}

variable "etcd_count" {
  type = number
}

variable "data_volume_size" {
  type    = number
  default = 1
}
