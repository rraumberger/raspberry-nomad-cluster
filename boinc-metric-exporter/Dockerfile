FROM golang:latest as build
WORKDIR /app

COPY go.mod ./
COPY *.go .

RUN CGO_ENABLED=0 GOOS=linux go build -o boinc-metric-exporter .

# Ubuntu is required as oneagentctl does not work properly with muslc and alpine
FROM ubuntu:latest
MAINTAINER Richard Raumberger <richard@raumberger.net>
COPY --from=build /app/boinc-metric-exporter /
ENTRYPOINT ["/boinc-metric-exporter"]
