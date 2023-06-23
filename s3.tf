module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "tala2app-s3-bucket"
  acl    = "public"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
}
