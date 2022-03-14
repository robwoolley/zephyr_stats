#!/usr/bin/env python3

import influxdb
import argparse
import sys

def parse_args():
    global args
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("-c", "--commit", required=True,
                        help="commit sha")
    parser.add_argument("-p", "--platform", help="Platform name", required=True)
    parser.add_argument("-d", "--database-url", help="Database DSN", required=True)
    args = parser.parse_args()


parse_args()

version = args.commit
platform = args.platform
influxdb_url = args.database_url


if not influxdb_url or not version or not platform:
    sys.exit("Missing arguments")

client = influxdb.InfluxDBClient.from_dsn(influxdb_url)
result = client.query(f"select * from builds where version = '{version}' and platform = '{platform}'")

if result:
    sys.exit(0)
else:
    sys.exit(1)
