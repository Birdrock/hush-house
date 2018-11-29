RELEASE_NAME := prod
NAMESPACE    := hush-house
CHART_DIR    := ./shuttle

all:
	@echo "Usage: upgrade | delete"


setup:
	helm init
	cd ../charts/stable/concourse && helm dependency update .
	helm dependency update $(CHART_DIR)


WEB_LOADBALANCER_IP=$(shell cd ./terraform && terraform output web-address)
METRICS_LOADBALANCER_IP=$(shell cd ./terraform && terraform output metrics-address)
upgrade: setup
	helm upgrade \
		--namespace $(NAMESPACE) \
		--set=concourse.web.service.loadBalancerIP=$(WEB_LOADBALANCER_IP) \
		--set=grafana.service.loadBalancerIP=$(METRICS_LOADBALANCER_IP) \
		--set=concourse.secrets.githubClientId=$(GITHUB_CLIENT_ID) \
		--set=concourse.secrets.githubClientSecret=$(GITHUB_CLIENT_SECRET) \
		--recreate-pods \
		--install \
		--debug \
		--wait \
		$(RELEASE_NAME) \
		$(CHART_DIR)


WEB_LOADBALANCER_IP=$(shell cd ./terraform && terraform output web-address)
METRICS_LOADBALANCER_IP=$(shell cd ./terraform && terraform output metrics-address)
plan: setup
	helm upgrade \
		--namespace $(NAMESPACE) \
		--set=concourse.web.service.loadBalancerIP=$(WEB_LOADBALANCER_IP) \
		--set=grafana.service.loadBalancerIP=$(METRICS_LOADBALANCER_IP) \
		--set=concourse.secrets.githubClientId=$(GITHUB_CLIENT_ID) \
		--set=concourse.secrets.githubClientSecret=$(GITHUB_CLIENT_SECRET) \
		--debug \
		--dry-run \
		--wait \
		$(RELEASE_NAME) \
		$(CHART_DIR)


delete:
	helm delete \
		--purge \
		$(RELEASE_NAME)
