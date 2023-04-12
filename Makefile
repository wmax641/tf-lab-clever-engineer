
IDENTITY=$(shell aws sts get-caller-identity | jq -r '.Arn' | cut -d':' -f5-)
ACCOUNT=$(shell echo "$(IDENTITY)" | cut -d":" -f1)

$(info $(IDENTITY))

fmtchk:
	terraform fmt -write=false -diff=true -check=true

fmtfix:
	terraform fmt -write=true --recursive

validate:
	terraform validate

plan:
	terraform plan -input=false -out=tfplan

apply:
	terraform apply -input=false tfplan

destroy:
	terraform plan -destroy -input=false -out=tfplan
	terraform apply -input=false tfplan
