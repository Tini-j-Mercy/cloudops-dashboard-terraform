output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "bastion_ip" {
  value = aws_instance.bastion.public_ip
}

output "asg_instance_ids" {
  value = aws_autoscaling_group.asg.instances
}
