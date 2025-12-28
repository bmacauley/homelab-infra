#------------------
# Makefile
#------------------

#------------------
# Variables
#------------------

#------------------
# Targets
#------------------


help: ## show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'




#--------------------------------------------
# install mise tools
#--------------------------------------------

install-mise-tools: ## install mise tools
	mise install





#--------------------------------------------
# layers
#--------------------------------------------

iventoy: ## proxmox-iventoy
	$(eval ENV := proxmox)
	$(eval LAYER := iventoy)




#--------------------------------------------
# terragrunt
#--------------------------------------------

# init plan apply output validate providers console refresh:
# 	cd $(ENV)/$(LAYER) && \
# 	terragrunt $@ \
# 		--non-interactive \
# 		--queue-include-external \
# 		--provider-cache \
# 		--provider-cache-dir ./.terragrunt-cache

plan apply destroy output validate providers console refresh:
	cd $(ENV)/$(LAYER) && \
	TF_LOG=DEBUG \
	VAULT_LOG_LEVEL=debug \
	terragrunt $@ \
		--non-interactive \
		--queue-include-external \
		--provider-cache \
		--provider-cache-dir ./.terragrunt-cache

force-unlock: ## force unlock the terragrunt lock
# eg make <layer> force-unlock LOCK_ID=1234567890
	cd $(ENV)/$(LAYER) && \
		terragrunt force-unlock $(LOCK_ID)


#--------------------------------------------
# vault
#--------------------------------------------


#--------------------------------------------
# consul
#--------------------------------------------




#--------------------------------------------
# helpers
#--------------------------------------------



clean: ## clean up cache directories
	@find . -type d -name ".terraform" -prune -exec rm -rf {} \;
	@find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;

clean-locks: ## Clean up terragrunt lock files
	@find . -name ".terraform.lock.hcl" -prune -exec rm -rf {} \;

clean-plugin-cache: ## Clean up the terraform plugin cache
	@rm -rf .terraform-plugin-cache

clean-all: clean clean-locks clean-plugin-cache
