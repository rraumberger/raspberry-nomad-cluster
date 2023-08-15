job "telegraf" {
  datacenters = ["homenet"]
  type        = "service"

  constraint {
    distinct_hosts = true
  }

  constraint {
    attribute = "${node.class}"
    value = "controller"
  }

  group "telegraf" {
    count = 1

    restart {
      attempts = 5
      interval = "15m"
    }

    reschedule {
      delay          = "30s"
      delay_function = "constant"
      unlimited      = true
    }

    task "telegraf" {
      driver = "docker"

      config {
        image = "telegraf:1.27.3"
        image_pull_timeout = "15m"
        volumes = [
          "local/telegraf.conf:/etc/telegraf/telegraf.conf:ro",
        ]
      }

      user = "telegraf"

      vault {
        policies = ["homelab"]
      }

      template {
        change_mode = "noop"
        destination = "local/telegraf.conf"

        data = <<EOH
[agent]
omit_hostname = true

[[inputs.haproxy]]
  servers = [
    {{ range service "haproxy-ui" }}
    "https://{{ .Address }}:{{ .Port }}/haproxy?stats",
    {{ end }}
  ]
  insecure_skip_verify = true


## TODO this is broken as it generates a new custom metric per line in the prometheus log
#[[inputs.prometheus]]
#  urls = [
#{{ range nodes }}
#  "http://{{ .Address }}:4646/v1/metrics?format=prometheus",
#{{ end }}
#  ]

################# Shelly Plug #################

[[inputs.mqtt_consumer]]
  servers = ["tcp://mqtt.lab.raumberger.net:1883"]

  ## Topics that will be subscribed to.
  topics = [
    "shellies/+/relay/0/power",
    "shellies/+/relay/0/energy",
    "shellies/+/temperature"
  ]
  topic_tag = ""
  data_format = "value"
  data_type = "float"
  client_id = "telegraf-shelly-plug"

  [[inputs.mqtt_consumer.topic_parsing]]
    topic = "shellies/+/+/+/+"
    tags = "_/shelly/_/_/_"
    measurement = "_/_/_/_/measurement"

  [[inputs.mqtt_consumer.topic_parsing]]
    topic = "shellies/+/+"
    tags = "_/shelly/_"
    measurement = "_/_/measurement"


################# Shelly HT #################

[[inputs.mqtt_consumer]]
  servers = ["tcp://mqtt.lab.raumberger.net:1883"]

  ## Topics that will be subscribed to.
  topics = [
    "shellies/+/sensor/temperature",
    "shellies/+/sensor/humidity",
    "shellies/+/sensor/battery",
    "shellies/+/sensor/error"
  ]
  name_prefix = "shelly-ht."
  topic_tag = ""
  data_format = "value"
  data_type = "float"
  client_id = "telegraf-shelly-ht"

  [[inputs.mqtt_consumer.topic_parsing]]
    topic = "shellies/+/+/+"
    tags = "_/shelly/_/_"
    measurement = "_/_/_/measurement"

################# Mikrotik #################

# CPU
[[inputs.mqtt_consumer]]
  servers = ["tcp://mqtt.lab.raumberger.net:1883"]
  topics = [
    "mikrotik/v1/telemetry"
  ]
  topic_tag = ""
  data_format = "json_v2"
  client_id = "telegraf-cpu"

  [[inputs.mqtt_consumer.json_v2]]
    measurement_name = "mikrotik"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "identity"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "model"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "sn"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "ros"

    [[inputs.mqtt_consumer.json_v2.field]]
        path = "cpu"
        type = "uint"

# POE Consumption
[[inputs.mqtt_consumer]]
  servers = ["tcp://mqtt.lab.raumberger.net:1883"]
  topics = [
    "mikrotik/v1/telemetry"
  ]
  topic_tag = ""
  data_format = "json_v2"
  client_id = "telegraf-poe"

  [[inputs.mqtt_consumer.json_v2]]
    measurement_name = "mikrotik"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "identity"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "model"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "sn"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "ros"

    [[inputs.mqtt_consumer.json_v2.field]]
        path = "poeConsumption"
        type = "uint"

# Uptime
[[inputs.mqtt_consumer]]
  servers = ["tcp://mqtt.lab.raumberger.net:1883"]
  topics = [
    "mikrotik/v1/telemetry"
  ]
  topic_tag = ""
  data_format = "json_v2"
  client_id = "telegraf-uptime"

  [[inputs.mqtt_consumer.json_v2]]
    measurement_name = "mikrotik"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "identity"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "model"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "sn"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "ros"

    [[inputs.mqtt_consumer.json_v2.field]]
        path = "uptime"
        type = "uint"

# Memory
[[inputs.mqtt_consumer]]
  servers = ["tcp://mqtt.lab.raumberger.net:1883"]
  topics = [
    "mikrotik/v1/telemetry"
  ]
  topic_tag = ""
  data_format = "json_v2"
  client_id = "telegraf-memory"

  [[inputs.mqtt_consumer.json_v2]]
    measurement_name = "mikrotik"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "identity"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "model"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "sn"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "ros"

    [[inputs.mqtt_consumer.json_v2.object]]
        path = "memory"
        tags = ["type"]

        [inputs.mqtt_consumer.json_v2.object.fields]
          memory = "uint"

# Temperature
[[inputs.mqtt_consumer]]
  servers = ["tcp://mqtt.lab.raumberger.net:1883"]
  topics = [
    "mikrotik/v1/telemetry"
  ]
  topic_tag = ""
  data_format = "json_v2"
  client_id = "telegraf-temperature"

  [[inputs.mqtt_consumer.json_v2]]
    measurement_name = "mikrotik"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "identity"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "model"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "sn"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "ros"

    [[inputs.mqtt_consumer.json_v2.object]]
        path = "temp"
        tags = ["sensor"]

        [inputs.mqtt_consumer.json_v2.object.fields]
          temp = "float"

# Fan Speed
[[inputs.mqtt_consumer]]
  servers = ["tcp://mqtt.lab.raumberger.net:1883"]
  topics = [
    "mikrotik/v1/telemetry"
  ]
  topic_tag = ""
  data_format = "json_v2"
  client_id = "telegraf-fan"

  [[inputs.mqtt_consumer.json_v2]]
    measurement_name = "mikrotik"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "identity"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "model"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "sn"

    [[inputs.mqtt_consumer.json_v2.tag]]
        path = "ros"

    [[inputs.mqtt_consumer.json_v2.object]]
        path = "fans"
        tags = ["fan"]

        [inputs.mqtt_consumer.json_v2.object.fields]
          rpm = "uint"



{{with secret "homelab/data/dynatrace"}}
[[outputs.dynatrace]]
  url = "https://{{.Data.data.activeGateHost}}/e/{{.Data.data.tenantId}}/api/v2/metrics/ingest"
  api_token = "{{.Data.data.metricIngestToken}}"
{{end}}
  prefix = "telegraf"
  insecure_skip_verify = true

EOH
      }
    }
  }
}
