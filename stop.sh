#!/bin/bash

function reverse_word_order {
    local result
    for word in $@; do
        result="$word $result"
    done
    echo "$result"
}

# InfluxDB
INFLUX_MF="pvc secrets config deployment service"
INFLUXDB_DIR="influxdb"
for MF in $(reverse_word_order ${INFLUX_MF}); do
    if [ ! -e ${INFLUXDB_DIR}/${MF}.yaml ]; then
        echo "Could not find ${INFLUXDB_DIR}/${MF}.yaml"
        exit 1
    fi
    kubectl delete -f ${INFLUXDB_DIR}/${MF}.yaml
done

# Chronograf
CHRONOGRAF_MF="pvc deployment service"
CHRONOGRAF_DIR="chronograf"
for MF in $(reverse_word_order ${CHRONOGRAF_MF}); do
    if [ ! -e ${CHRONOGRAF_DIR}/${MF}.yaml ]; then
        echo "Could not find ${CHRONOGRAF_DIR}/${MF}.yaml"
        exit 1
    fi
    kubectl delete -f${CHRONOGRAF_DIR}/${MF}.yaml
done

# Grafana
GRAFANA_MF="pvc secrets config config-dashboards config-datasources deployment service"
GRAFANA_DIR="grafana"
for MF in $(reverse_word_order ${GRAFANA_MF}); do
    if [ ! -e ${GRAFANA_DIR}/${MF}.yaml ]; then
        echo "Could not find ${GRAFANA_DIR}/${MF}.yaml"
        exit 1
    fi
    kubectl delete -f ${GRAFANA_DIR}/${MF}.yaml
done
