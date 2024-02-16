.PHONY: brew-deps
brew-deps:
	brew install helm helmfile kubectl terraform awscli

terraform/.terraform:
	terraform -chdir=terraform/ init

.PHONY: tf-apply
tf-apply: terraform/.terraform
	terraform -chdir=terraform/ apply

.PHONY: kube-config
kube-config: tf-apply
	aws eks update-kubeconfig --name helmfile-demo-cluster --alias helmfile-demo-cluster

.PHONY: charts
charts: kube-config
	helmfile sync -f helmfile/

.PHONY: clean-terraform
clean-terraform: clean-charts terraform/.terraform
	terraform -chdir=terraform/ destroy; rm -rf terraform/.terraform

.PHONY: clean-charts
clean-charts:
	{ \
	helmfile delete -f helmfile/ --selector name=helmfile-demo ;\
	helmfile delete -f helmfile/ ;\
	}

.PHONY: clean
clean: clean-terraform

.PHONY: all
all: charts
