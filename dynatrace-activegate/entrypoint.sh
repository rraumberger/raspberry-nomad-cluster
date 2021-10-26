#!/bin/sh

# Replace config placeholders
sed -i "s/NETWORK_ZONE_PLACEHOLDER/${DYNATRACE_NETWORK_ZONE}/" /ag/config/config/custom.properties
sed -i "s/AG_GROUP_PLACEHOLDER/${DYNATRACE_AG_GROUP}/" /ag/config/config/custom.properties
sed -i "s/ENTRYPOINT_PLACEHOLDER/${DYNATRACE_AG_ENTRYPOINT}/" /ag/config/config/custom.properties

# Run Activegate
java -classpath "/ag/install/lib/*" ${DYNATRACE_AG_JVM_ARGS} -XX:ErrorFile=/var/log/dynatrace/gateway/hs_err_pid_%p.log -Duser.language=en -Djava.util.logging.manager=com.compuware.apm.logging.impl.backend.CustomShutdownLogManager -Djdk.tls.ephemeralDHKeySize=2048 -Dorg.xerial.snappy.lib.path=/ag/install/lib/native -Dorg.xerial.snappy.lib.name=libsnappyjava.so com.compuware.apm.collector.core.CollectorImpl -CONFIG_DIR /ag/config/config
