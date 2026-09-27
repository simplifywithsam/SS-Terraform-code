#!/usr/bin/env bash
# Build the sample app image and push it to Artifactory.
#
# Required env vars:
#   ARTIFACTORY_REGISTRY   e.g. mycompany.jfrog.io  (or artifactory.statestr.com)
#   ARTIFACTORY_REPO       Docker repo key, e.g. iec-docker-local
#   ARTIFACTORY_USER       Artifactory username / service account
#   ARTIFACTORY_TOKEN      Artifactory API key or access token
# Optional:
#   IMAGE_NAME             default: iec-sample-app
#   IMAGE_TAG              default: git short SHA, else timestamp
#   BASE_IMAGE             base image override (e.g. pulled via Artifactory remote)
#   PIP_INDEX_URL          Artifactory PyPI remote URL
set -euo pipefail

: "${ARTIFACTORY_REGISTRY:?Set ARTIFACTORY_REGISTRY}"
: "${ARTIFACTORY_REPO:?Set ARTIFACTORY_REPO}"
: "${ARTIFACTORY_USER:?Set ARTIFACTORY_USER}"
: "${ARTIFACTORY_TOKEN:?Set ARTIFACTORY_TOKEN}"

IMAGE_NAME="${IMAGE_NAME:-iec-sample-app}"
IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)}"
IMAGE_REF="${ARTIFACTORY_REGISTRY}/${ARTIFACTORY_REPO}/${IMAGE_NAME}:${IMAGE_TAG}"

cd "$(dirname "$0")"

BUILD_ARGS=()
[[ -n "${BASE_IMAGE:-}" ]]    && BUILD_ARGS+=(--build-arg "BASE_IMAGE=${BASE_IMAGE}")
[[ -n "${PIP_INDEX_URL:-}" ]] && BUILD_ARGS+=(--build-arg "PIP_INDEX_URL=${PIP_INDEX_URL}")

echo ">> Logging in to ${ARTIFACTORY_REGISTRY}"
echo "${ARTIFACTORY_TOKEN}" | docker login "${ARTIFACTORY_REGISTRY}" -u "${ARTIFACTORY_USER}" --password-stdin

echo ">> Building ${IMAGE_REF} (linux/amd64 for Fargate X86_64)"
docker build --platform linux/amd64 ${BUILD_ARGS[@]+"${BUILD_ARGS[@]}"} -t "${IMAGE_REF}" .

echo ">> Pushing ${IMAGE_REF}"
docker push "${IMAGE_REF}"

echo
echo "Pushed: ${IMAGE_REF}"
echo "Set in ecs-service/dev.tfvars:  container_image = \"${IMAGE_REF}\""
