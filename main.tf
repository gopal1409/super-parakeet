##lets create the s3 bucket
resource "aws_s3_bucket" "playgoup_s3_bucket" {
  bucket = "${var.prefix}-playground-${var.env}"
  lifecycle {
    prevent_destroy = false
  }
}