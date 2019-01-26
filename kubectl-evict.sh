#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Option parsing is hard... see https://stackoverflow.com/a/29754866
# All of this is so we can parse -n and --namespace...
! getopt --test > /dev/null
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo >&2 'Error: `getopt --test` failed in this environment.'
    exit 1
fi

OPTIONS=n:
LONGOPTS=debug,force,output:,verbose

# -use ! and PIPESTATUS to get exit code with errexit set
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
  # e.g. return value is 1
  #  then getopt has complained about wrong arguments to stdout
  exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

namespace=''
# parse the options in order until we see --
while true; do
  case "$1" in
    -n|--namespace)
      namespace="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      echo >&2  "Unhandled option: $1" # OPTIONS doesn't match case statement
      exit 3
      ;;
  esac
done

# handle non-option arguments
if [[ $# -ne 1 ]]; then
  echo >&2  "$0: A pod name is required."
  exit 4
fi

pod_name="$1"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${REPO_ROOT}"

if [[ -z "${namespace}" ]]; then
  current_context="$(kubectl config current-context)"
  namespace="$(kubectl config view -o jsonpath="{.contexts[?(@.name=='${current_context}')].context.namespace}")"
  if [[ -z "${namespace}" ]]; then
    namespace="default"
  fi
fi

cat << EOF | scripts/kubectl-curl.sh api/v1/namespaces/${namespace}/pods/${pod_name}/eviction -H 'Content-type:application/json' -X POST -d @-
{
  "apiVersion": "policy/v1beta1",
  "kind": "Eviction",
  "metadata": {
    "name": "${pod_name}",
    "namespace": "${namespace}"
  }
}
EOF
