#!/usr/bin/env bats

load _helpers

############################################################
# Daemonset Consul Agent
############################################################
@test "deployment: Daemonset Consul Agent Environment variables are set" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/deployment.yaml  \
      --set 'config.useNodeAgent.enabled=false' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env | length' | tee /dev/stderr)

  [ "${actual}" = '1' ]

  local env=$(helm template \
      --show-only templates/deployment.yaml  \
      --set 'config.useNodeAgent.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers[0].env' | tee /dev/stderr)
  local actual=$(echo "${env}" | \
      jq -r 'length' | tee /dev/stderr)
  [ "${actual}" = '2' ]

  local actual=$(echo "${env}" | \
      jq -r '.[0].name' | tee /dev/stderr)
  [ "${actual}" = 'HOST_IP' ]

  local actual=$(echo "${env}" | \
      jq -r '.[1].name' | tee /dev/stderr)
  [ "${actual}" = 'CONSUL_HTTP_ADDR' ]
}

@test "deployment: token.secretKey is required when token.secretName is set" {
  cd `chart_dir`

  run helm template \
      -s templates/deployment.yaml  \
      --set 'config.token.secretName=name' \ .
  [ "$status" -eq 1 ]
  [[ "$output" =~ "both config.token.secretKey and config.token.secretName must be set if one of them is provided" ]]
}

@test "deployment: token.secretName is required when token.secretKey is set" {
  cd `chart_dir`

  run helm template \
      -s templates/deployment.yaml  \
      --set 'config.token.secretKey=name' \ .
  [ "$status" -eq 1 ]
  [[ "$output" =~ "both config.token.secretKey and config.token.secretName must be set if one of them is provided" ]]
}

############################################################
# TLS
############################################################
@test "deployment: Init Container for auto encrypt is present" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.initContainers | length' | tee /dev/stderr)

  [ "${actual}" = '1' ]

  local actual=$(helm template \
      --show-only templates/deployment.yaml  \
      --set 'config.tls.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.initContainers | length' | tee /dev/stderr)

  [ "${actual}" = '1' ]

  local actual=$(helm template \
      --show-only templates/deployment.yaml  \
      --set 'config.tls.enabled=true' \
      --set 'config.tls.autoEncrypt.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.initContainers | length' | tee /dev/stderr)

  [ "${actual}" = '2' ]
}

@test "deployment: Consul Template Container for auto encrypt is present" {
  cd `chart_dir`

  local actual=$(helm template \
      --show-only templates/deployment.yaml  \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers | length' | tee /dev/stderr)

  [ "${actual}" = '1' ]

  local actual=$(helm template \
      --show-only templates/deployment.yaml  \
      --set 'config.tls.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers | length' | tee /dev/stderr)

  [ "${actual}" = '1' ]

  local actual=$(helm template \
      --show-only templates/deployment.yaml  \
      --set 'config.tls.enabled=true' \
      --set 'config.tls.autoEncrypt.enabled=true' \
      . | tee /dev/stderr |
      yq -r '.spec.template.spec.containers | length' | tee /dev/stderr)

  [ "${actual}" == '2' ]
}
