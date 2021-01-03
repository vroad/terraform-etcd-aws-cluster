locals {
  asg_names             = [for i in range(var.etcd_count) : "${module.this.id}-${i}"]
  etcd_servers          = [for i in range(0, var.etcd_count) : format("%s.%s", local.asg_names[i], var.dns_zone)]
  etcd_ebs_volume_names = [for i in range(0, var.etcd_count) : format("%s-data-%s", module.this.id, i)]
  asg_tags = [for i in range(0, var.etcd_count) : merge(module.this.tags, {
    Name = local.asg_names[i]
  })]
}

data "ct_config" "ignitions" {
  count = module.this.enabled ? var.etcd_count : 0
  content = templatefile("ignition.yaml", {
    assets_bucket = module.assets_bucket.bucket_id
    etcd_servers  = join(",", local.etcd_servers)
  })
}

resource "aws_launch_template" "etcds" {
  count = module.this.enabled ? var.etcd_count : 0

  name = local.asg_names[count.index]
  tags = module.this.tags

  tag_specifications {
    resource_type = "instance"

    tags = merge(module.this.tags, {
      "asg-route53-lambda:private-hosted-zone-id" = var.dns_zone_id
      "asg-route53-lambda:private-dns-records"    = local.etcd_servers[count.index]
    })
  }

  tag_specifications {
    resource_type = "volume"

    tags = module.this.tags
  }

  update_default_version = true

  image_id  = var.flatcar_ami_id
  user_data = base64encode(data.ct_config.ignitions[count.index].rendered)

  iam_instance_profile {
    name = aws_iam_instance_profile.etcd.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type = var.disk_type
      volume_size = var.disk_size
      iops        = var.disk_iops
      throughput  = var.disk_throughput
      encrypted   = true
    }
  }

  vpc_security_group_ids = [aws_security_group.etcd[0].id]
}

resource "aws_autoscaling_group" "etcds" {
  count = module.this.enabled ? var.etcd_count : 0

  name = aws_launch_template.etcds[count.index].name
  tags = [for key, value in local.asg_tags[count.index] : {
    key                 = key
    value               = value
    propagate_at_launch = false
  }]

  desired_capacity          = 1
  min_size                  = 0
  max_size                  = 1
  default_cooldown          = 30
  health_check_grace_period = 30

  vpc_zone_identifier = [element(var.public_subnets, count.index)]

  capacity_rebalance = var.capacity_rebalance
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.etcds[count.index].id
        version            = aws_launch_template.etcds[count.index].latest_version
      }

      dynamic "override" {
        for_each = var.instance_types

        content {
          instance_type = override.value
        }
      }
    }

    instances_distribution {
      on_demand_percentage_above_base_capacity = var.on_demand_percentage_above_base_capacity
      spot_allocation_strategy                 = var.spot_allocation_strategy
    }
  }

  wait_for_capacity_timeout = 0

  initial_lifecycle_hook {
    name                    = "launching"
    default_result          = "ABANDON"
    heartbeat_timeout       = 60
    lifecycle_transition    = "autoscaling:EC2_INSTANCE_LAUNCHING"
    notification_target_arn = module.asg-route53-lambda.sns_topic_arn
    role_arn                = module.asg-route53-lambda.sns_role_arn
  }
  initial_lifecycle_hook {
    name                    = "terminating"
    default_result          = "CONTINUE"
    heartbeat_timeout       = 60
    lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
    notification_target_arn = module.asg-route53-lambda.sns_topic_arn
    role_arn                = module.asg-route53-lambda.sns_role_arn
  }

  depends_on = [
    aws_s3_bucket_object.etcd-manager-assets,
    aws_s3_bucket_object.cfssl,
    aws_s3_bucket_object.cfssljson,
  ]
}

resource "aws_ebs_volume" "data" {
  count             = module.this.enabled ? var.etcd_count : 0
  availability_zone = element(local.availability_zones, count.index)
  encrypted         = true

  type = var.disk_type
  iops = var.disk_iops
  size = var.data_volume_size

  tags = {
    Name = local.etcd_ebs_volume_names[count.index]
  }
}
