module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "virgo-bucket"
  acl    = "public"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
}
