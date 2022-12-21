FROM registry.home.estelsmith.com/alpine:3.17 AS builder

ARG GOTIFY_VERSION="2.2.0"
ENV GOTIFY_VERSION=${GOTIFY_VERSION}

RUN apk --no-cache add make bash git go nodejs yarn
RUN echo Building with $(go version), node $(node --version), yarn $(yarn --version)
RUN git clone --branch "v${GOTIFY_VERSION}" --single-branch --depth 1 https://github.com/gotify/server.git build

WORKDIR /build
RUN make download-tools && go get -d

WORKDIR /build/ui
RUN yarn install
# Starting with Node 17, yarn won't build the UI without these NODE_OPTIONS
# @see https://github.com/nodejs/node/blob/main/doc/changelogs/CHANGELOG_V17.md#openssl-30
RUN NODE_OPTIONS="--openssl-legacy-provider" yarn build

WORKDIR /build
RUN go run hack/packr/packr.go
RUN export BUILDDATE=$(date "+%F-%T")\
    && export COMMIT=$(git rev-parse --verify HEAD)\
    && export LD_FLAGS="-w -s -X main.Version=${GOTIFY_VERSION} -X main.BuildDate=${BUILDDATE} -X main.Commit=${COMMIT} -X main.Mode=prod"\
    && go build -ldflags="${LD_FLAGS}" -o gotify-server

# ---

FROM registry.home.estelsmith.com/alpine:3.17

RUN adduser -S -s /sbin/nologin -h /app -H -D appuser

RUN mkdir -p /app/data && chown appuser /app/data
COPY --from=builder /build/gotify-server /app/gotify-server
COPY config.yml /app/config.yml

USER appuser
WORKDIR /app
EXPOSE 8080
ENTRYPOINT ["/app/gotify-server"]
