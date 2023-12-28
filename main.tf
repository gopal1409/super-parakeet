##lets create the s3 bucket
resource "aws_s3_bucket" "playgoup_s3_bucket" {
  bucket = "${var.prefix}-playground-${var.env}"
  lifecycle {
    prevent_destroy = false
  }
}

### IAM ###

data "aws_iam_policy_document" "glue_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["glue.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "s3_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.playgoup_s3_bucket.arn,
      "${aws_s3_bucket.playgoup_s3_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_role" "glue_service_role" {
  name               = "${var.prefix}-glue-service-role-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.glue_policy_document.json
}

resource "aws_iam_role_policy_attachment" "glue_service_role_policy_attachment" {
    role = aws_iam_role.glue_service_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_service_role_policy" {
  name   = "${var.prefix}-glue-service-role-policy-${var.env}"
  policy = data.aws_iam_policy_document.s3_policy_document.json
  role   = aws_iam_role.glue_service_role.id
}

### GLUE ###

resource "aws_glue_job" "blogpost_job" {
  name              = "${var.prefix}-blogpost-job-${var.env}"
  role_arn          = aws_iam_role.glue_service_role.arn
  glue_version      = "3.0"
  number_of_workers = 2
  worker_type       = "G.1X"
  max_retries       = "1"
  timeout           = 2880
  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.playgoup_s3_bucket.bucket}/blogpost/glue-jobs/blogpost_job.py"
  }
  default_arguments = {
    "--enable-auto-scaling"              = "true"
    "--enable-continuous-cloudwatch-log" = "true"
  }
}