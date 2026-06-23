# === Defaults Variables ===
PORT=8080
IMAGE="ghcr.io/badges/shields:latest"
CONTAINER_NAME="shields-local"
STARTUP_TIMEOUT=60

set -e

# === Parse Options ===
while [ "$#" -gt 0 ]; do
  case "$1" in
    --port) PORT="${2:-$PORT}"; shift 2 ;;
    --image) IMAGE="${2:-$IMAGE}"; shift 2 ;;
    --container-name) CONTAINER_NAME="${2:-$CONTAINER_NAME}"; shift 2 ;;
    --startup-timeout) STARTUP_TIMEOUT="${2:-$STARTUP_TIMEOUT}"; shift 2 ;;
    \?) echo "::error::Invalid options $1" >&2; exit 1 ;;
  esac
done

# === Main Script ===
# Remove any leftover container with the same name
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

# Pull image
echo "Pulling Docker image: ${IMAGE}"
docker pull "${IMAGE}"

# Run the container
echo "Starting shields.io service in Docker container ${CONTAINER_NAME} on port ${PORT}..."
docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart no \
  -p "${PORT}:8080" \
  "${IMAGE}"

SERVICE_URL="http://localhost:${PORT}"

# Wait for the service to become ready
echo "Waiting for the shields.io service to become ready (timeout: ${STARTUP_TIMEOUT}s)..."
elapsed=0
until curl -s "${SERVICE_URL}" >/dev/null 2>&1; do
  if [ "${elapsed}" -ge "${STARTUP_TIMEOUT}" ]; then
    echo "::error::Timeout waiting for the shields.io service to become ready."
    docker logs "${CONTAINER_NAME}" 2>&1 || true
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
    exit 1
  fi
  sleep 2
  elapsed=$((elapsed + 2))
done

echo "Shields.io service is ready at ${SERVICE_URL}"

# Set the output for GitHub Actions
echo "service_url=${SERVICE_URL}" >> "$GITHUB_OUTPUT"

# Set the state for GitHub Actions
echo "SHIELDS_CONTAINER_NAME=${CONTAINER_NAME}" >> "$GITHUB_STATE"

# Register cleanup for self-hosted runners
# Useful if the runner supports ACTIONS_RUNNER_HOOK_JOB_COMPLETED hook
HOOK_DIR="${RUNNER_TEMP:-/tmp}"
CLEANUP_SCRIPT="${HOOK_DIR}/shields_cleanup_${CONTAINER_NAME}.sh"
cat > "${CLEANUP_SCRIPT}" <<'EOF'
#!/bin/sh
CONTAINER="${SHIELDS_CONTAINER_NAME:-shields-local}"
echo "Stopping shields.io container '${CONTAINER}'..."
docker rm -f "${CONTAINER}" 2>/dev/null || true
EOF
chmod +x "${CLEANUP_SCRIPT}"
echo "Cleanup script created at ${CLEANUP_SCRIPT}. It will be executed on runner shutdown."
