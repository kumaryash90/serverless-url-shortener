terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~>5.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_dynamodb_table" "links" {
    name = "url-shortener-links"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "slug"
    attribute {
        name = "slug"
        type = "S"
    }
    ttl {
        attribute_name = "expires_at"
        enabled = true
    }
}