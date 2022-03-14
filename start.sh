#!/bin/bash

# InfluxDB
INFLUX_MF="pvc secrets config deployment service"
INFLUXDB_DIR="influxdb"
for MF in ${INFLUX_MF}; do
    if [ ! -e ${INFLUXDB_DIR}/${MF}.yaml ]; then
        echo "Could not find ${INFLUXDB_DIR}/${MF}.yaml"
        exit 1
    fi
    kubectl apply -f${INFLUXDB_DIR}/${MF}.yaml
done

# Chronograf
CHRONOGRAF_MF="pvc deployment service"
CHRONOGRAF_DIR="chronograf"
for MF in ${CHRONOGRAF_MF}; do
    if [ ! -e ${CHRONOGRAF_DIR}/${MF}.yaml ]; then
        echo "Could not find ${CHRONOGRAF_DIR}/${MF}.yaml"
        exit 1
    fi
    kubectl apply -f${CHRONOGRAF_DIR}/${MF}.yaml
done

# Grafana
GRAFANA_MF="pvc secrets config config-dashboards config-datasources deployment service"
GRAFANA_DIR="grafana"
for MF in ${GRAFANA_MF}; do
    if [ ! -e ${GRAFANA_DIR}/${MF}.yaml ]; then
        echo "Could not find ${GRAFANA_DIR}/${MF}.yaml"
        exit 1
    fi
    kubectl apply -f${GRAFANA_DIR}/${MF}.yaml
done