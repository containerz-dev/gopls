# syntax = docker.io/docker/dockerfile:1.1.3-experimental

# target: gopls-builder
ARG GOLANG_VERSION
ARG ALPINE_VERSION
FROM docker.io/golang:${GOLANG_VERSION}-alpine${ALPINE_VERSION} AS gopls-builder
ENV OUTDIR=/out \
	GO111MODULE='on'

RUN set -eux && \
	apk add --no-cache \
		ca-certificates \
		git
RUN set -eux && \
	mkdir -p "${OUTDIR}/usr/bin" && \
	CGO_ENABLED=0 GOBIN=${OUTDIR}/usr/bin/ go get -a -v -tags='osusergo,netgo,static,static_build' -installsuffix='netgo' -ldflags='-d -s -w "-extldflags=-fno-PIC -static"' \
		golang.org/x/tools/gopls@master

# target: nonroot
FROM gcr.io/distroless/static:nonroot AS nonroot

# target: gopls
FROM scratch AS gopls
COPY --from=nonroot /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=nonroot /etc/passwd /etc/passwd
COPY --from=nonroot /etc/group /etc/group
COPY --from=gopls-builder --chown=nonroot:nonroot /out/ /
USER nonroot:nonroot

ENTRYPOINT ["/usr/bin/gopls"]
