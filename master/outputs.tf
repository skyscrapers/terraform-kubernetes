output "master_sg" {
  value = "${aws_security_group.masters.id}"
}

output "k8s_data_bucket" {
  value = "${aws_s3_bucket.k8s_data.bucket}"
}
