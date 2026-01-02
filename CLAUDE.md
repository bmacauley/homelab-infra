# CLAUDE.md

This document provides guidance for Claude Code when working in this repository. It defines the conventions, structure, and safe-editing rules for all terraform and terragrunt files used to setup VM's or LXC containers in Proxmox.


The conventions below apply strictly to anything that is developed in this repository.
When using third-party content (e.g. Terraform modules), aim to align with these conventions where reasonable, but a perfect match is not required.

---

## Project Scope

This repository manages a proxmox environment using Terraform & Terragrunt. It includes:
Configuration and lifecycle management for physical and virtual servers
Standard roles for system setup, networking, storage, containers, monitoring, and supporting services
Playbooks for provisioning, updating, and auditing node state
Python helper scripts that generate inventory or retrieve external secrets
Core principles: idempotency, reproducibility, and minimal drift.

---
## Workflow Conventions

### Running terragrunt

Use the Makefile layer pattern to set context and run terragrunt operations:

```bash
# View available commands
make help

# Install required tools (mise)
make install-mise-tools

# Common operations (plan, apply, destroy, validate, output, providers, console, refresh)
make iventoy plan
make iventoy apply
make iventoy destroy
make iventoy output
make iventoy validate
make iventoy providers

# Force unlock if state is stuck
make iventoy force-unlock LOCK_ID=1234567890
```

Layer targets set `ENV` and `LAYER` variables, then chain to terragrunt targets. All terragrunt commands run with `--non-interactive`, `--queue-include-external`, and provider caching enabled.

### Validation & Testing

```bash
# Validate terragrunt configuration
make iventoy validate

# Check provider versions
make iventoy providers

# View outputs
make iventoy output

# Clean cache directories (safe to run)
make clean          # .terraform and .terragrunt-cache
make clean-locks    # .terraform.lock.hcl files
make clean-all      # all cache and lock files

# Interactive console for debugging
make iventoy console
```

---



### Git Workflow & Pull Requests

When developing features, Claude must:

1. **Create a feature branch** from the main branch (or current base branch)
   - Use descriptive branch names: `feat/<feature-name>`, `fix/<issue-name>`, etc.

2. **Make incremental, logical commits** that tell a story
   - Each commit should represent a single, understandable step in the feature development
   - Break down large features into smaller, reviewable commits
   - Examples of good commit granularity:
     - "Add defaults/main.yml with initial variables"
     - "Implement task to install package dependencies"
     - "Add template for service configuration"
     - "Add handlers for service restart"
     - "Update playbook to include new role"
   - Avoid monolithic commits that mix multiple concerns (e.g., "Add new role" with 20 files changed)

3. **Write clear commit messages**
   - Use imperative mood: "Add role defaults" not "Added role defaults"
   - First line should be concise (50-72 chars) and summarize the change
   - Include body explaining the "why" if the commit is non-obvious
   - Reference related issues/PRs when applicable

4. **Create a Pull Request** when the feature is complete or ready for review
   - PR title should clearly describe what the feature does
   - PR description should explain:
     - What the feature adds/changes
     - Why it's needed
     - Any breaking changes or migration steps
     - How to test the changes
   - Keep PRs focused on a single feature or fix
   - If a feature is large, consider breaking it into multiple PRs

5. **Commit incrementally during development**
   - Don't wait until the end to commit everything
   - Commit working, logical units as you build them
   - This makes it easier to review, debug, and rollback if needed

Example of good incremental commits for a new role:
```
feat: add terragrunt layer for a iventoyinstance
feat(iventoy): add defaults and variables

```

---


## Repository Architecture

### Directory Structure
```
homelab-infra/
├──root.hcl
├──global.hcl
├──proxmox/
│  └──<proxmox vm/lxc container>
│    └──terragrunt.hcl
├──terraform/
│  └──<module>
│     ├──variables.tf
│     ├──main.tf
│     └──ouputs.tf
├──mise.toml
├──README.md
├──.gitignore
└──Makefile
```

---

## Editing Rules for Claude

### Required Behaviors
- Preserve all directory and naming conventions.


## Makefile Conventions

The Makefile provides a uniform interface for operational tasks. All targets must be non-interactive, idempotent, safe to run multiple times, and explicit about outputs.

### Target Documentation

All user-facing targets must use `##` comments for help text:
```makefile
target-name: ## description appears in make help
```

The `help` target auto-extracts these. Undocumented targets are implementation details.

### Layer Pattern

Layer targets set context variables and chain to terragrunt operations:
```makefile
layer-name: ## environment-layer-name
	$(eval ENV := proxmox)
	$(eval LAYER := layer-name)
```

Usage: `make layer-name plan` sets ENV/LAYER, then runs `plan`.

### Terragrunt Commands

Terragrunt targets use pattern rules and require ENV/LAYER from layer targets:
```makefile
plan apply destroy output validate providers console refresh:
	cd $(ENV)/$(LAYER) && \
	terragrunt $@ --non-interactive --queue-include-external \
		--provider-cache --provider-cache-dir ./.terragrunt-cache
```

Required flags: `--non-interactive`, `--queue-include-external`, `--provider-cache`.

### Structure

Organize targets into sections with comment dividers:
```makefile
#--------------------------------------------
# section name
#--------------------------------------------
```

Use `@` prefix to suppress command echo for cleanup/helper targets.

### Adding Targets

1. Place in appropriate section (layers, terragrunt, helpers, etc.)
2. Add `##` help comment
3. Follow existing patterns for similar operations
4. Ensure idempotency (safe to run multiple times)
