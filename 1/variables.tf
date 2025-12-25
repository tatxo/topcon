variable "vpc_cidr_block" {
  description = "VPC network"
  default     = "10.10.0.0/16"
}

variable "pub-subnet" {
  type = list(map(string))
  default = [
    {
      name              = "public-subnet-1"
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
    },
    {
      name              = "public-subnet-2"
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-1b"
    }
  ]
}

variable "pri-subnet" {
  type = list(map(string))
  default = [
    {
      name              = "private-subnet-1"
      cidr_block        = "10.0.101.0/24"
      availability_zone = "us-east-1a"
    },
    {
      name              = "private-subnet-2"
      cidr_block        = "10.0.102.0/24"
      availability_zone = "us-east-1b"
    }
  ]
}

variable "region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "ecs_cluster_name" {
  description = "Topcon ECS cluster"
  default     = "topcon-ecs"
}

variable "arm64_ami" {
  default = "ami-0b0225832e18295a1"
}

variable "db_name" {
  description = "DB name"
  default     = "wordpressdb"
}

variable "db_user" {
  description = "DB username"
  default     = "ecs"
}

variable "db_root_password" {
  description = "DB root password"
  default     = "ProconMirageRoot00-"
}

variable "db_password" {
  description = "DB password"
  default     = "ProconMirage00-"
}

variable "db_engine" {
  default = "8.0"
}

variable "wp_user" {
  description = "Wordpress username"
  default     = "admin"
}

variable "wp_password" {
  description = "Wordpress password"
  default     = "ProconMirage00-"
}

variable "alert_mail" {
  description = "Email to receive alerts"
  default     = "miguel@tatxo.com"
}
