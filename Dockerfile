# Hugo development environment using Docker with Alpine Linux
# This Dockerfile ensures consistent Hugo versions across all environments
# Alpine version: 3.20.2
# Hugo version: 0.128.2
# Pinned to prevent unexpected breaking changes from updates
# Update these versions manually when upgrading

FROM alpine:3.20.2

# Install dependencies for downloading and extracting Hugo
RUN apk add --no-cache wget ca-certificates && \
    # Download Hugo binary for Linux aarch64 (Apple Silicon)
    wget -q https://github.com/gohugoio/hugo/releases/download/v0.128.2/hugo_0.128.2_Linux-arm64.tar.gz -O /tmp/hugo.tar.gz && \
    # Extract to /usr/local/bin
    tar -xzf /tmp/hugo.tar.gz -C /usr/local/bin && \
    # Verify installation
    hugo version && \
    # Cleanup
    rm /tmp/hugo.tar.gz && \
    apk del wget

WORKDIR /src

EXPOSE 1313

ENTRYPOINT ["hugo"]
CMD ["server", "--bind", "0.0.0.0"]

