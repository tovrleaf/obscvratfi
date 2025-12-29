# Hugo development environment using Docker
# This Dockerfile ensures consistent Hugo versions across all environments
# Hugo version: 0.128.2-alpine
# Pinned to prevent unexpected breaking changes from Hugo updates
# Update this version manually when upgrading Hugo

FROM klakegg/hugo:0.128.2-alpine

WORKDIR /src

EXPOSE 1313

ENTRYPOINT ["hugo"]
CMD ["server", "--bind", "0.0.0.0"]
