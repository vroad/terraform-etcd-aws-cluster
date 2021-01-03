resource "aws_security_group" "etcd" {
  count  = module.this.enabled ? 1 : 0
  vpc_id = var.vpc_id
  name   = module.this.id
  tags   = module.this.tags
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.etcd[0].id

  type             = "egress"
  protocol         = "-1"
  from_port        = 0
  to_port          = 0
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}
