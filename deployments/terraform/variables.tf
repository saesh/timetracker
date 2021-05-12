variable "aws_profile_name" {
    description = "AWS profile to use"
    type        = string
    default     = "default"
}

variable "aws_region" {
    description = "AWS region to deploy to"
    type        = string
    default     = "us-east-1"
}

variable "project_name" {
    description = "Project name to use as default name for creating resources"
    type        = string
    default     = "timetracker"
}