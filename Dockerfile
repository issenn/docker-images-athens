# syntax=docker/dockerfile:1

ARG BUILDPLATFORM="linux/amd64"

FROM --platform=${BUILDPLATFORM} alpine:3.17 AS prepare

SHELL ["/bin/ash", "-eufo", "pipefail", "-c"]

RUN apk --no-cache add \
    curl=~7.87.0 \
    # sed=~4.9 \
    git=~2.38 \
    # go=~1.19.5 \
    # bash=~5.2.15 \
    ca-certificates=~20220614 && \
    sync

ARG PACKAGE_NAME
ARG PACKAGE_VERSION
ARG PACKAGE_VERSION_PREFIX
ARG PACKAGE_URL
ARG PACKAGE_SOURCE_URL
ARG PACKAGE_HEAD_URL
ARG PACKAGE_HEAD=false

# hadolint ignore=SC2015
RUN { [ -n "${PACKAGE_VERSION_PREFIX}" ] && PACKAGE_VERSION="${PACKAGE_VERSION_PREFIX}${PACKAGE_VERSION}" || true; } && mkdir -p "/usr/local/src/${PACKAGE_NAME}" && \
    [ -n "${PACKAGE_NAME}" ] && \
    { { [ -n "${PACKAGE_HEAD_URL}" ] && \
        git clone "${PACKAGE_HEAD_URL}" "/usr/local/src/${PACKAGE_NAME}" && \
        { { { [ -n "${PACKAGE_VERSION}" ] && [ "${PACKAGE_HEAD}" != true ] && [ "${PACKAGE_HEAD}" != "on" ] && [ "${PACKAGE_HEAD}" != "1" ] && \
              git -C "/usr/local/src/${PACKAGE_NAME}" checkout tags/${PACKAGE_VERSION}; } && \
            { [ -n "${PACKAGE_VERSION}" ] && [ "${PACKAGE_HEAD}" != true ] && [ "${PACKAGE_HEAD}" != "on" ] && [ "${PACKAGE_HEAD}" != "1" ]; }; } || \
          { { ! { [ -n "${PACKAGE_VERSION}" ] && [ "${PACKAGE_HEAD}" != true ] && [ "${PACKAGE_HEAD}" != "on" ] && [ "${PACKAGE_HEAD}" != "1" ] && \
              git -C "/usr/local/src/${PACKAGE_NAME}" checkout tags/${PACKAGE_VERSION}; }; } && \
            { ! { [ -n "${PACKAGE_VERSION}" ] && [ "${PACKAGE_HEAD}" != true ] && [ "${PACKAGE_HEAD}" != "on" ] && [ "${PACKAGE_HEAD}" != "1" ]; }; }; }; }; } || \
      { [ -n "${PACKAGE_SOURCE_URL}" ] && curl -fsSL "${PACKAGE_SOURCE_URL}" | \
        tar -zxC "/usr/local/src/${PACKAGE_NAME}" --strip 1; } || \
      { [ -n "${PACKAGE_URL}" ] && [ -n "${PACKAGE_VERSION}" ] && \
        curl -fsSL "${PACKAGE_URL}/archive/${PACKAGE_VERSION}.tar.gz" | \
        tar -zxC "/usr/local/src/${PACKAGE_NAME}" --strip 1; }; } || false

# ----------------------------------------------------------------------------

FROM --platform=${BUILDPLATFORM} golang:1.19.5-alpine3.17 AS build

RUN apk --no-cache add \
    # curl=~7.87.0 \
    # sed=~4.9 \
    git=~2.38 \
    # go=~1.19.5 \
    # bash=~5.2.15 \
    ca-certificates=~20220614 && \
    sync

SHELL ["/bin/ash", "-eufo", "pipefail", "-c"]

ARG PACKAGE_NAME
ARG PACKAGE_VERSION
ARG PACKAGE_URL
ARG PACKAGE_SOURCE_URL
ARG PACKAGE_HEAD_URL
ARG PACKAGE_HEAD=false

ARG TARGETOS TARGETARCH TARGETVARIANT
ARG CGO_ENABLED=0
ARG BUILD_FLAGS="-v"
ARG GO111MODULE
ARG GOPROXY
ARG GOSUMDB

ENV GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH}

COPY --from=prepare /etc/passwd /etc/group /etc/
COPY --from=prepare /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=prepare --chown=nonroot:nonroot /usr/local/src /usr/local/src

WORKDIR /usr/local/src/${PACKAGE_NAME}

RUN --mount=type=cache,target=/home/nonroot/.cache/go-build,uid=65532,gid=65532 \
    --mount=type=cache,target=/go/pkg \
        COMMIT_SHA="$(git describe --dirty --always)" && \
        BUILD_DATE="$(date -u +%Y-%m-%d-%H:%M:%S-%Z)" && \
        TARGETVARIANT=$(printf "%s" "${TARGETVARIANT}" | sed 's/v//g') && \
        CGO_ENABLED=${CGO_ENABLED} GOOS=${TARGETOS} GOARCH=${TARGETARCH} GOARM=${TARGETVARIANT} \
        go build ${BUILD_FLAGS} -ldflags="-s -w -X github.com/gomods/athens/pkg/build.version=${COMMIT_SHA} -X github.com/gomods/athens/pkg/build.buildDate=${BUILD_DATE}" -o ${PACKAGE_NAME} ./cmd/proxy && \
        sync

WORKDIR /etc/${PACKAGE_NAME}

RUN cp -a /usr/local/src/${PACKAGE_NAME}/config.dev.toml ./

COPY config.toml ./

RUN chmod 644 /etc/${PACKAGE_NAME}/config.toml /etc/${PACKAGE_NAME}/config.dev.toml

# ----------------------------------------------------------------------------

FROM --platform=${BUILDPLATFORM} alpine:3.17

ARG PACKAGE_NAME

COPY --from=build /etc/passwd /etc/group /etc/
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=build /usr/local/src/${PACKAGE_NAME}/${PACKAGE_NAME} /usr/local/bin/
COPY --from=build --chown=nobody:nogroup /etc/${PACKAGE_NAME} /etc/${PACKAGE_NAME}
COPY --from=build /usr/local/go/bin/go /usr/local/bin/

RUN apk --no-cache add \
    git=~2.38 \
    git-lfs=~3.2.0 \
    # mercurial=~6.3.1 \
    openssh-client=~9.1 \
    subversion=~1.14.2 \
    procps=~3.3.17 \
    fossil=~2.20 \
    tini=~0.19.0 && \
    mkdir -p /usr/local/go

# TODO: switch to 'nonroot' user
# USER nobody

# EXPOSE 3000

ENTRYPOINT [ "/sbin/tini", "--" ]

CMD ["athens", "-config_file=/etc/athens/config.toml"]
