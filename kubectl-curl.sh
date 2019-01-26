#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

if [[ $# -lt 1 ]]; then
  echo >&2  "$0: A url path is required."
  exit 4
fi
api_path="$1"
shift
curl_args=("$@")

current_context="$(kubectl config current-context)"

# Extract the apiserver URL
cluster_name="$(kubectl config view -o jsonpath="{.contexts[?(@.name=='${current_context}')].context.cluster}")"
server_address="$(kubectl config view -o jsonpath="{.clusters[?(@.name=='${cluster_name}')].cluster.server}")"

# Extract the auth token
user_name="$(kubectl config view -o jsonpath="{.contexts[?(@.name=='${current_context}')].context.user}")"
auth_token="$(kubectl config view -o jsonpath="{.users[?(@.name=='${user_name}')].user.auth-provider.config.access-token}")"

# Download the apiserver certificate authority public key for TLS verification
default_secret_name="$(kubectl get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='default')].metadata.name}")"
ca_crt=$(kubectl get secrets "${default_secret_name}" -o jsonpath="{.data['ca\.crt']}" | base64 --decode)
local_tmp_dir="$(mktemp -d "${TMPDIR:-/tmp/}$(basename "$0").XXXXXXXXXXXX")"
trap "rm -rf '${local_tmp_dir}'" EXIT
echo "${ca_crt}" > "${local_tmp_dir}/ca.crt"

curl --location --fail --connect-timeout 5 \
  --header "Authorization: Bearer ${auth_token}" \
  --cacert "${local_tmp_dir}/ca.crt" \
  "${server_address}/${api_path}" \
  $([[ ${#curl_args[@]} -gt 0 ]] && echo "${curl_args[@]}" || echo)
#TODO: does the above preserve quotes around args as intended?
