#!/bin/bash

sudo docker buildx build --platform linux/arm64 -t registry.lab.raumberger.net/boinc-metric-exporter:1.0.3 --push .