clean:
	rm -f *.tfstate*
	rm -rf .terraform
	rm -rf ../repos/*

init:
	terraform $@

plan:
	terraform $@

apply: 
	terraform $@ -auto-approve

destroy:
	terraform $@
