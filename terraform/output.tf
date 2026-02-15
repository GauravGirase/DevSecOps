output "public_ip" {
  value = aws_instance.bastion.public_ip
}
output "ssh_command" {
  value = "ssh -i 'new-keypair.pem' ubuntu@${aws_instance.bastion.public_dns}"
}