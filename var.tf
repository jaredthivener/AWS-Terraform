variable "region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-east-1" # Update this with your desired region
}

variable "subnet_ids" {
  description = "List of subnet IDs for the RDS cluster"
  type        = list(string)
  default     = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"] # Update this with your private subnet IDs
}

variable "master_username" {
  description = "The master username for the RDS cluster"
  type        = string
  default     = "admin" # Update this with your desired username
}

variable "backup_retention_period" {
  description = "The number of days to retain backups for the RDS cluster"
  type        = number
  default     = 7 # Update this based on your disaster recovery requirements
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection on the RDS cluster"
  type        = bool
  default     = true # Update this based on your environment (true for production, false for development)
}

variable "databases" {
  default = {
    "db1" : {
      engine         = "aurora-mysql"
      engine_version = "8.0"
      instance_type  = "db.r5.large"
      replica_count  = 2
    },
    "db2" : {
      engine         = "aurora-postgresql"
      engine_version = "16.0"
      instance_type  = "db.r5.large"
      replica_count  = 2
    },
    "db3" : {
      engine         = "aurora-mysql"
      engine_version = "8.0"
      instance_type  = "db.t3.medium"
      replica_count  = 2
    },
    # Add more databases as needed
  }
}