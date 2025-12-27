output "s3_remote_state_bucket" {
  value       = length(aws_s3_bucket.tf_state) > 0 ? aws_s3_bucket.tf_state[0].bucket : ""
  description = "S3 bucket used for remote state (if created)"
}

output "dynamodb_table" {
  value       = length(aws_dynamodb_table.tf_lock) > 0 ? aws_dynamodb_table.tf_lock[0].name : ""
  description = "DynamoDB lock table name (if created)"
}
