resource "aws_launch_template" "bastion" {
  name_prefix   = "asg-bastion"
  image_id      = "ami-0758470213bdd23b1"
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "bar" {
  availability_zones = ["us-east-1a", "us-east-1c"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_template {
    id      = ["${aws_launch_template.bastion.id}"]
    version = "$Latest"
  }
}
