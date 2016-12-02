data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_autoscaling_group" "workers" {
  name                 = "k8s-worker-${var.project}"
  launch_configuration = "${aws_launch_configuration.worker.id}"
  max_size             = "${var.max_amount_workers}"
  min_size             = 1
  availability_zones   = ["${data.aws_availability_zones.available.names}"]
  vpc_zone_identifier  = ["${var.subnets}"]
  termination_policies = ["OldestLaunchConfiguration", "ClosestToNextInstanceHour", "OldestInstance"]
  health_check_type    = "EC2"                                                                        # Should be changed later to elb when we have a good check target

  tag {
    key                 = "Name"
    value               = "k8s-worker-${var.project}"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s-role"
    value               = "worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "${var.project}"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "worker" {
  name_prefix                 = "k8s-worker-${var.project}-"
  image_id                    = "${var.ami}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  security_groups             = ["${aws_security_group.workers.id}"]
  iam_instance_profile        = "${aws_iam_instance_profile.workers.name}"
  associate_public_ip_address = false
  user_data                   = "${data.template_file.user_data.rendered}"

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}


data "template_file" "user_data" {
  template = "${file("${path.module}/../templates/worker/worker-cloud-config.tpl")}"

  vars {
    project     = "${var.project}"
    environment = "${var.environment}"
    k8s_version = "v1.4.6_coreos.0"
  }
}
