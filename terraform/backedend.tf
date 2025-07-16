terraform {
  backend "s3" {
    bucket         = "weather-app-infra"             
    key            = "dev/terraform.tfstate"         
    region         = "us-east-1"                     
    encrypt        = true                            # Encrypt the state file at rest
  }
}

