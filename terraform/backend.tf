terraform {
  backend "s3" {
    bucket = "devsecops-terraform-state-2026"
    key = "dev/terraform.tfstate"
    region = "ap-south-1"
    use_lockfile = true
    encrypt = true
  }
}