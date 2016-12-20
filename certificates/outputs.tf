output "k8s_data_bucket" {
  value = "${aws_s3_bucket.k8s_data.id}"
}
