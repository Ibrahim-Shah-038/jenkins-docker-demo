# Look up the existing instance by id or public IP (one of the two is expected)
data "aws_instance" "existing" {
  count      = var.existing_instance_id != "" ? 1 : 0
  instance_id = var.existing_instance_id
}

# Fallback: search by public IP
data "aws_instances" "by_ip" {
  count = var.existing_instance_public_ip != "" && var.existing_instance_id == "" ? 1 : 0
  filter {
    name   = "ip-address"
    values = [var.existing_instance_public_ip]
  }
}

# Optional: create S3 bucket and DynamoDB table for remote state locking
resource "aws_s3_bucket" "tf_state" {
  count  = var.s3_remote_state && length(var.s3_bucket_name) > 0 ? 1 : 0
  bucket = var.s3_bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "tf_lock" {
  count        = var.s3_remote_state && length(var.dynamodb_table_name) > 0 ? 1 : 0
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Optional: create dedicated Jenkins IAM user with a narrow policy
resource "aws_iam_user" "jenkins" {
  count = var.create_jenkins_user ? 1 : 0
  name  = var.jenkins_user_name
  path  = "/"
  tags  = { created_by = "terraform" }
}

resource "aws_iam_user_policy" "jenkins_policy" {
  count = var.create_jenkins_user ? 1 : 0
  name  = "${var.jenkins_user_name}-policy"
  user  = aws_iam_user.jenkins[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:*"]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:*"]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:Describe*", "ssm:SendCommand", "ssm:ListCommandInvocations"]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_access_key" "jenkins_key" {
  count = var.create_jenkins_user ? 1 : 0
  user  = aws_iam_user.jenkins[0].name
}

# Helpful outputs
output "instance_id" {
  value       = var.existing_instance_id != "" ? var.existing_instance_id : (length(data.aws_instances.by_ip) > 0 ? data.aws_instances.by_ip[0].ids[0] : "")
  description = "Existing instance id (if provided or discovered)"
}

output "instance_public_ip" {
  value       = var.existing_instance_public_ip != "" ? var.existing_instance_public_ip : (length(data.aws_instances.by_ip) > 0 ? data.aws_instances.by_ip[0].public_ips[0] : (length(data.aws_instance.existing) > 0 ? data.aws_instance.existing[0].public_ip : ""))
  description = "Instance public IP (if provided or discovered)"
}

output "jenkins_access_key_id" {
  value       = var.create_jenkins_user && length(aws_iam_access_key.jenkins_key) > 0 ? aws_iam_access_key.jenkins_key[0].id : ""
  sensitive   = true
  description = "Access key id for Jenkins (save into Jenkins AWS credential)"
}

output "jenkins_secret_access_key" {
  value       = var.create_jenkins_user && length(aws_iam_access_key.jenkins_key) > 0 ? aws_iam_access_key.jenkins_key[0].secret : ""
  sensitive   = true
  description = "Secret access key for Jenkins (save into Jenkins AWS credential)"
}
