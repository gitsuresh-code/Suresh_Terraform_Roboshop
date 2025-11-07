terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "6.16.0"
    }
  }
  backend "s3" {
    bucket = "roboshop-dev-suresh"
    key = "vpc-demo"
    use_lockfile = true
    encrypt = true
    region = "us-east-1"
    
  }
}

provider "aws" {
    region = "us-east-1"
}