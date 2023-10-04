#!/usr/bin/env bash
set -Eeuo pipefail

# export TF_LOG=TRACE
script_dir=${PWD##*/}

printf "\e[1mTerraform wrapper...\e[0m\n"

args=("$@")

if [[ ${#args[@]} -eq 0 ]]; then
    terraform
    exit 1
fi

aws sts get-caller-identity

infra_root=$(git rev-parse --show-toplevel)

aws_env=${AWS_ENV:-dev}
tf_flags="-var-file=config/${aws_env}/variables.tfvars"
tf_backend=" --backend-config config/${aws_env}/backend.tfvars"

echo "backend: ${tf_backend}"
echo "flags: ${tf_flags}"

run_terraform(){
    terraform $@
}

case "$1" in
    init)
        rm -rf .terraform.lock.hcl
        rm -rf .terraform/terraform.tfstate
        run_terraform "$@" $tf_backend
        ;;
    plan)
        run_terraform "$@" $tf_flags
        ;;
    apply)
        run_terraform "$@" $tf_flags 
        ;;

    refresh)
        run_terraform "$@" $tf_flags
        ;;

    destroy)
        run_terraform "$@" $tf_flags
        ;;
    *)
        run_terraform "$@" 
        ;;
esac
