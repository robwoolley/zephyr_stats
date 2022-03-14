import click
import datetime
import influxdb

from . import client


def str2bool(v):
    vb = v.lower()
    if vb in ('yes', 'true', '1'):
        return True
    if vb in ('no', 'false', '0'):
        return False
    raise ValueError('{} cannot be converted to a boolean'.format(v))


CONVERTERS = {
    'int': int,
    'float': float,
    'bool': str2bool
}


class ContextArg(click.types.StringParamType):
    def convert(self, value, param, ctx):
        value = super(ContextArg, self).convert(value, param, ctx)
        parts = value.split(':')
        if len(parts) > 1:
            converter, arg = CONVERTERS[parts[0]], ':'.join(parts[1:])

        else:
            converter = lambda v: v
            arg = parts[0]
        parts = arg.split('=')
        try:
            arg, raw_value = parts[0], '='.join(parts[1:])
        except IndexError:
            self.fail('Invalid argument {}'.format(value))

        real_value = converter(raw_value)
        return arg, real_value


@click.command(
    help="""
    Extract test data from a junit file and send it to influxdb:

        junit2influx test.xml --influxdb-url url

    Each test is send as a single datapoint with its result and
    duration under the "tests" measurement, and overall data
    (number of tests, total duration, etc.) is sent under
    the "builds" measurement.

    You can provide additional tags and fields to be sent with
    each datapoint to influxdb by using the --field and --tag
    flags:

        junit2influx test.xml --influxdb-url url --tag host=myhost --field commit=dh876d0

    All additional tags and fields are sent as string by default, but
    you can cast them to specific json types (bool, float and int) if needed:

        --tag int:stage=1      # add an integer "stage" tag with a value of 1
        --tag bool:fake=true   # add a boolean "fake" tag with a value of True
        --field float:dur=3.5  # add a float "dur" field with a value of 3.5

    Multiple --field and --tag flags can be provided.
    """)
@click.argument('junit_file', type=click.Path(exists=True))
@click.option('--field', 'fields', type=ContextArg(), multiple=True)
@click.option('--tag', 'tags', type=ContextArg(), multiple=True)
@click.option('--influxdb-url', required=True)
@click.option('--timestamp', required=True)
def junit_push(junit_file, influxdb_url, fields, tags, timestamp):
    context = {
        'fields': {
            f: v
            for f, v in fields
        },
        'tags': {
            f: v
            for f, v in tags
        }
    }

    ts = datetime.datetime.fromtimestamp(int(timestamp))
    client.push(
        junit_file=junit_file,
        context=context,
        influxdb_url=influxdb_url,
        time=ts)
    click.echo('Data sent to influxdb!')


@click.command(
    help="""
    Push data directly to influxdb:

        push2influx measurement_name --influxdb-url url --tag result=success

    Tags and fields work the same way the do for junit2influx
    """)
@click.argument('measurement')
@click.option('--field', 'fields', type=ContextArg(), multiple=True)
@click.option('--tag', 'tags', type=ContextArg(), multiple=True)
@click.option('--influxdb-url', required=True)
def push(measurement, influxdb_url, fields, tags):
    now = datetime.datetime.now()
    point = {
        'measurement': measurement,
        'time': now.isoformat(),
        'fields': {
            f: v
            for f, v in fields
        },
        'tags': {
            f: v
            for f, v in tags
        }
    }
    client = influxdb.InfluxDBClient.from_dsn(influxdb_url)
    client.write_points([point])
    click.echo('Data sent to influxdb!')


if __name__ == '__main__':
    junit_push()
