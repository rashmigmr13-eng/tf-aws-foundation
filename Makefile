ENV ?= dev
init:
	terraform -chdir=stack init -reconfigure -backend-config=../envs/$(ENV).backend.hcl
plan: init
	terraform -chdir=stack plan -var-file=../envs/$(ENV).tfvars
apply: init
	terraform -chdir=stack apply -var-file=../envs/$(ENV).tfvars
lint:
	terraform fmt -recursive && tflint --recursive && checkov --config-file .checkov.yaml
cost:
	infracost breakdown --path stack --terraform-var-file ../envs/$(ENV).tfvars
