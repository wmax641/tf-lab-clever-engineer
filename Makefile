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
