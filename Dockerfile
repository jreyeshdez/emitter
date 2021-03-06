FROM golang:alpine AS builder

# Copy the directory into the container outside of the gopath
RUN mkdir -p /go-build/src/github.com/emitter-io/emitter/
WORKDIR /go-build/src/github.com/emitter-io/emitter/
ADD . /go-build/src/github.com/emitter-io/emitter/

# Download and install any required third party dependencies into the container.
RUN apk add --no-cache git g++ \
  && go install \
  && apk del g++

# Base image for runtime
FROM alpine:latest
RUN apk --no-cache add ca-certificates

WORKDIR /root/
# Get the executable binary from build-img declared previously
COPY --from=builder /go/bin/emitter .

# Expose emitter ports
# Internal port for clustering
EXPOSE 4000
# Port for HTTP
EXPOSE 8080
# Port for MQTT
EXPOSE 1883
# Port for MQTTS
EXPOSE 8883

# Start the broker
CMD ["./emitter"]
