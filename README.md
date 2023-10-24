# caf-component-aws-terragrunt

---
This repo contains shell script used to generate boilerplate code for terragrunt skeleton repositories.

It contains the following:

* tasks/boilerplate - Makefiles for performing terragrunt operations on your module to generate terragrunt boilerplate code.
* linkfiles/scripts - Shell script to generate terragrunt boilerplate code.

## Terragrunt boilerplate code generation

`linkfiles/scripts/tg-boilerplate-code.sh` file contains bash commands to generate terragrunt boilerplate code in skeleton repositories. The script is run using `make target` named `terragrunt/generate`.

The generated terragrunt boilerplate code is specific to AWS cloud platform.