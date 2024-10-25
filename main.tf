resource "aws_s3_bucket" "terraform_tfstate" {
  bucket = var.bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "s3_ownership_tfstate" {
  bucket = aws_s3_bucket.terraform_tfstate.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "s3_bucket_acl_tfstate" {
  depends_on = [aws_s3_bucket_ownership_controls.s3_ownership_tfstate]

  bucket = aws_s3_bucket.terraform_tfstate.id
  acl    = "private"
}
# Enable versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access
# resource "aws_s3_bucket_public_access_block" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true


# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}

# S3 bucket policy
# resource "aws_s3_bucket_policy" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid       = "RequireEncryptedTransport"
#         Effect    = "Deny"
#         Principal = "*"
#         Action    = "s3:*"
#         Resource = [
#           "${aws_s3_bucket.terraform_state.arn}/*",
#           aws_s3_bucket.terraform_state.arn
#         ]
#         Condition = {
#           Bool = {
#             "aws:SecureTransport" = "false"
#           }
#         }
#       }
#     ]
#   })
# }
