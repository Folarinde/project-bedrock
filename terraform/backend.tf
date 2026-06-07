terraform {
  backend "s3" {
    bucket = "bedrock-tf-state-folarinde-107554922064-us-east-1-an"   
    key    = "project-bedrock/terraform.tfstate"
    region = "us-east-1"

    # Enables state file versioning support (bucket versioning must be ON)
    use_path_style = false
  }
}