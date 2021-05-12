resource "random_string" "bucket_suffix" {
  length  = 5
  special = false
  upper   = false
}

module "timetracker_s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${var.project_name}-${random_string.bucket_suffix.result}"
  acl    = "private"
  block_public_acls       = true 
  block_public_policy     = true 
  ignore_public_acls      = true 
  restrict_public_buckets = true
  
  tags = {
    Name        = var.project_name
  }
}