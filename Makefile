# Satcorporation Paved Road — single entry point
#
# This Makefile is what a developer actually types. They don't need to
# remember whether something is a Terraform command, an Ansible command,
# or a Python script — they just run `make <target>`.

.PHONY: help provision harden harden-puppet review-terraform review-ansible ask scan destroy

help:
	@echo "Satcorporation Paved Road — available commands:"
	@echo ""
	@echo "  make provision BUCKET=my-app-logs ENV=dev   - Provision secure infra via Terraform"
	@echo "  make harden                                  - Apply baseline OS hardening via Ansible"
	@echo "  make harden-puppet                           - Apply baseline OS hardening via Puppet (alternative)"
	@echo "  make review-terraform FILE=path/to/main.tf   - AI security review of Terraform code"
	@echo "  make review-ansible FILE=path/to/playbook.yml - AI security review of Ansible code"
	@echo "  make ask Q=\"your security question\"          - Ask the AI assistant a question"
	@echo "  make scan                                     - Run tfsec + checkov locally"
	@echo "  make destroy                                  - Tear down provisioned infrastructure"

provision:
	cd ansible && ansible-playbook provision-paved-road.yml -e "bucket_name=$(BUCKET)" -e "environment=$(ENV)"

harden:
	cd ansible && ansible-playbook provision-paved-road.yml --tags hardening

harden-puppet:
	puppet apply puppet/manifests/site.pp

review-terraform:
	cd ai-assistant && python3 security-assistant.py review $(FILE)

review-ansible:
	cd ai-assistant && python3 security-assistant.py review $(FILE)

ask:
	cd ai-assistant && python3 security-assistant.py ask "$(Q)"

scan:
	tfsec terraform/
	checkov -d terraform/

destroy:
	cd terraform/example-usage && terraform destroy -auto-approve
