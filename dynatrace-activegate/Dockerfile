FROM ubuntu:latest

ARG SNAPPY_VERSION="1.1.8.4"
ARG ZSTD_VERSION="1.5.0-4"
ARG DYNATRACE_ENVIRONMENT_URL
ARG DYNATRACE_PAAS_TOKEN
ARG DYNATRACE_AG_VERSION

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install wget unzip openjdk-11-jre -y \
    && rm -rf /var/lib/apt/lists/*

RUN wget --quiet "${DYNATRACE_ENVIRONMENT_URL}/api/v1/deployment/installer/gateway/unix/version/${DYNATRACE_AG_VERSION}?arch=x86" --header="Authorization: Api-Token ${DYNATRACE_PAAS_TOKEN}" -O activegateInstaller.sh
RUN sh activegateInstaller.sh -s INSTALL=/ag/install CONFIG=/ag/config PACKAGES_DIR=/ag/packages \
    && rm activegateInstaller.sh

# Delete bundled JRE and Native Libs
RUN rm -r /ag/install/jre && rm /ag/install/lib/native/*

# Install correct snappy native lib
RUN mkdir snappy \
    && cd snappy \
    && wget --quiet "https://repo1.maven.org/maven2/org/xerial/snappy/snappy-java/${SNAPPY_VERSION}/snappy-java-${SNAPPY_VERSION}.jar" -O snappy-java.jar \
    && unzip snappy-java.jar \
    && mv org/xerial/snappy/native/Linux/aarch64/libsnappyjava.so /ag/install/lib/native/libsnappyjava.so \
    && cd / \
    && rm -r snappy

# Install correct zstd native lib
RUN mkdir zstd \
    && cd zstd \
    && wget --quiet "https://repo1.maven.org/maven2/com/github/luben/zstd-jni/${ZSTD_VERSION}/zstd-jni-${ZSTD_VERSION}-linux_aarch64.jar" -O zstd-jni.jar \
    && unzip zstd-jni.jar \
    && mv "linux/aarch64/libzstd-jni-${ZSTD_VERSION}.so" /ag/install/lib/native/libzstd-jni.so \
    && cd / \
    && rm -r zstd

ADD custom.properties /ag/config/config/custom.properties
ADD entrypoint.sh /ag/entrypoint.sh

ENTRYPOINT ["sh", "/ag/entrypoint.sh"]
