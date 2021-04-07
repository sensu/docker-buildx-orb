# shellcheck disable=SC2148
if uname -a | grep "x86_64 GNU/Linux"; then
    export PLATFORM=linux-amd64
elif uname -a | grep "aarch64 GNU/Linux"; then
    export PLATFORM=linux-arm64
else
    echo "Platform not supported."
    uname -a
    exit 1
fi
echo "Platform $PLATFORM"

echo "Installing Docker buildx"
mkdir -p ~/.docker/cli-plugins
baseUrl="https://github.com/docker/buildx/releases/download"
fileName="buildx-v${BUILDX_VERSION}.${PLATFORM}"
url="${baseUrl}/v${BUILDX_VERSION}/${fileName}"
curl -sSL -o ~/.docker/cli-plugins/docker-buildx "${url}"
chmod a+x ~/.docker/cli-plugins/docker-buildx

echo "Enabling experimental Docker features"
echo 'export DOCKER_CLI_EXPERIMENTAL="enabled"' >> "${BASH_ENV}"

echo "Initializing Docker buildx"
docker buildx install

echo "Starting binfmt container"
docker run --rm --privileged tonistiigi/binfmt:"${BINFMT_TAG}" --install all

echo "Removing any buildx multiarch container instances"
docker rm -f buildx_buildkit_docker-multiarch0

echo "Creating docker-multiarch builder"
docker buildx create --name docker-multiarch \
    --platform linux/386 \
    --platform linux/amd64 \
    --platform linux/arm/v5 \
    --platform linux/arm/v6 \
    --platform linux/arm/v7 \
    --platform linux/arm64 \
    --platform linux/mips64le \
    --platform linux/ppc64le \
    --platform linux/riscv64 \
    --platform linux/s390x

echo "Inspecting & bootstrapping docker-multiarch builder"
docker buildx inspect --builder docker-multiarch --bootstrap

echo "Setting docker-multiarch as the default builder"
docker buildx use docker-multiarch
