NAME_PREFIX ?= demo-svc
REGION ?= eastus
ENVIRONMENT ?= dev
ENV_INSTANCE ?= 000
CONTAINER_NAME ?= tfstate
STORAGE_ACCOUNT_NAME ?= $(subst -,,$(NAME_PREFIX)sa$(REGION)$(ENVIRONMENT)$(ENV_INSTANCE)tf) # 24 char limit
RESOURCE_GROUP_NAME ?= $(NAME_PREFIX)-rg-$(REGION)-$(ENVIRONMENT)-$(ENV_INSTANCE)-tfstate

.PHONY: terragrunt/remote_state/azure
terragrunt/remote_state/azure:
	az group create --name $(RESOURCE_GROUP_NAME) --location $(REGION)
	az storage account create --resource-group $(RESOURCE_GROUP_NAME) --name $(STORAGE_ACCOUNT_NAME) --sku Standard_LRS --encryption-services blob
	az storage container create --name $(CONTAINER_NAME) --account-name $(STORAGE_ACCOUNT_NAME)
