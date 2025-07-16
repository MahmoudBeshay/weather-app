terraform {
  backend "s3" {
    bucket = "weather-app-infra"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}

