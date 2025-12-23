output "app_ip" {
  value = aws_instance.nodes[0].public_ip
}

output "monitor_ip" {
  value = aws_instance.nodes[1].public_ip
}
