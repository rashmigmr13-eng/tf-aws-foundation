bucket         = "REPLACE-tfstate-bucket"
key            = "foundation/prod/terraform.tfstate"
region         = "ap-south-1"
dynamodb_table = "REPLACE-tfstate-bucket-lock"
encrypt        = true
