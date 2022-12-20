FROM registry.home.estelsmith.com/alpine:3.17 AS build

ARG GOTIFY_VERSION="2.2.0"
ENV GOTIFY_VERSION=${GOTIFY_VERSION}

RUN apk --no-cache add make bash git go nodejs yarn
COPY build.sh /build.sh
RUN chmod +x /build.sh ** /build.sh

# ---

FROM registry.home.estelsmith.com/alpine:3.17

RUN mkdir /app
COPY --from=build /build/gotify-server /app/gotify-server
