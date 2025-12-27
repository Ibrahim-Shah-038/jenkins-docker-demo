variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "existing_instance_id" {
  description = "(Optional) existing EC2 instance id to reference"
  type        = string
  default     = ""
}

variable "existing_instance_public_ip" {
  description = "(Optional) existing EC2 public IP to locate instance when id not known"
  type        = string
  default     = ""
}

variable "create_jenkins_user" {
  description = "If true, create an IAM user for Jenkins and return access keys (sensitive)"
  type        = bool
  default     = true
}

variable "jenkins_user_name" {
  description = "Name for the Jenkins IAM user"
  type        = string
  default     = "jenkins-ci"
}

variable "s3_remote_state" {
  description = "Enable creating S3 bucket + DynamoDB for remote state"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "Name to create for Terraform state bucket (if s3_remote_state=true)"
  type        = string
  default     = ""
}

variable "dynamodb_table_name" {
  description = "Name to create for DynamoDB state lock table (if s3_remote_state=true)"
  type        = string
  default     = ""
}
