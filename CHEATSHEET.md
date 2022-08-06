# Force restart Nomad Job

`nomad job eval -force-reschedule <job-name>`

# Mikrotik MQTT Stat script

```
# Required packages: iot

################################ Configuration ################################
# Name of an existing MQTT broker that should be used for publishing
:local broker "mqtt-homelab"

# MQTT topic where the message should be published
:local topic "mikrotik/v1/telemetry"

#################################### System ###################################
:put ("[*] Gathering system info...")
:local cpuLoad [/system resource get cpu-load]
:local totalMemory [/system resource get total-memory]
:local freeMemory [/system resource get free-memory]
:local usedMemory ($totalMemory - $freeMemory)
:local rosVersion [/system package get value-name=version \
  [/system package find where name ~ "^routeros"]]
:local model [/system routerboard get value-name=model]
:local serialNumber [/system routerboard get value-name=serial-number]

:local identity [/system/identity get name]


#################################### Uptime ###################################
:put ("[*] Calculating Uptime...")
:local uptime [/system resource get uptime];
:local weekend 0;
:local dayend 0;
:local weeks 0;
:local days 0;

:if ([:find $uptime "w" -1] > 0) do={
    :set weekend [:find $uptime "w" -1];
    :set weeks [:pick $uptime 0 $weekend];
    :set weekend ($weekend+1);
};

:if ([:find $uptime "d" -1] > 0) do={
    :set dayend [:find $uptime "d" -1];
    :set days [:pick $uptime $weekend $dayend];
};

:local time [:pick $uptime ([:len $uptime]-8) [:len $uptime]];

:local hours [:pick $time 0 2];
:local minutes [:pick $time 3 5];
:local seconds [:pick $time 6 8];

:local uptimeSeconds [($weeks*86400*7+$days*86400+$hours*3600+$minutes*60+$seconds)];

#################################### Health ###################################
:put ("[*] Gathering Health Stats...")
:local temperature [/system/health/get [/system/health/find where name=temperature] value]
:local cpuTemperature [/system/health/get [/system/health/find where name=cpu-temperature] value]
:local sfpTemperature [/system/health/get [/system/health/find where name=sfp-temperature] value]
:local fan1Speed [/system/health/get [/system/health/find where name=fan1-speed] value]
:local fan2Speed [/system/health/get [/system/health/find where name=fan2-speed] value]
:local boardTemp1 [/system/health/get [/system/health/find where name=board-temperature1] value]
:local boardTemp2 [/system/health/get [/system/health/find where name=board-temperature2] value]
:local poeConsumption 0
#:local poeConsumption [/system/health/get [/system/health/find where name=poe-out-consumption] value]

#################################### MQTT #####################################
:local message \
  "{\"identity\":\"$identity\",\
  \"model\":\"$model\",\
  \"sn\":\"$serialNumber\",\
  \"ros\":\"$rosVersion\",\
  \"cpu\":$cpuLoad,\
  \"uptime\":$uptimeSeconds,\
  \"poeConsumption\":$poeConsumption,\
  \"memory\":[{\"type\":\"total\", \"memory\":$totalMemory},{\"type\":\"free\", \"memory\":$freeMemory},{\"type\":\"used\", \"memory\":$usedMemory}],\
  \"fans\":[{\"fan\":1, \"rpm\":$fan1Speed},{\"fan\":2, \"rpm\":$fan2Speed}],\
  \"temp\":[{\"sensor\":\"general\", \"temp\":$temperature},\
 {\"sensor\":\"cpu\", \"temp\":$cpuTemperature},\
 {\"sensor\":\"sfp\", \"temp\":$sfpTemperature},\
 {\"sensor\":\"board1\", \"temp\":$boardTemp1},\
 {\"sensor\":\"board2\", \"temp\":$boardTemp2}]}"

#:log info "$message";
:put ("[*] Total message size: $[:len $message] bytes")
:put ("[*] Sending message to MQTT broker...")
/iot mqtt publish broker=$broker topic=$topic message=$message
:put ("[*] Done")
```