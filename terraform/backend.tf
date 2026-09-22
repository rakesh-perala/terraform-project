terraform {
  backend "s3" {
    bucket       = "shopsphere-terraform-state-652310866649"
    key          = "platform/dev/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }
}
