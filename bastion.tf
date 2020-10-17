resource "aws_key_pair" "bastion_key" {
  key_name   = "mykeypair"
  public_key = "${file(mykey.pub)}"
}

output "bastion_public_ip" {
  value = "${aws_instance.bastion-hosts.public_ip}"
}

resource "aws_instance" "bastion-hosts" {
  ami                         = "ami-0758470213bdd23b1"
  instance_type               = t2.micro
  key_name                    = ["${aws_key_pair.bastion_key.key_name}"]
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = local.disk_size
    delete_on_termination = true
  }
  tags = {
    Name = "Bastion host"
  }
}
