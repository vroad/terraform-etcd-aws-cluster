terraform {
  required_version = ">= 0.13.0, < 0.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.21.0, < 4.0"
    }
    ct = {
      source  = "poseidon/ct"
      version = ">= 0.7.1, < 1.0"
    }
  }
}
