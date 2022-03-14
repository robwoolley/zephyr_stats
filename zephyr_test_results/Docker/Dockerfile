FROM debian:11

RUN apt-get update && apt-get install -y python3-pip git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# COPY requirements.txt requirements.txt

COPY junit2influx-0.2.1 junit2influx-0.2.1

RUN cd junit2influx-0.2.1 && pip3 install .

RUN mkdir -p /data/zephyr

RUN mkdir -p /data/test_results

COPY check.py check.py

COPY import.sh import.sh

CMD [ "/bin/bash", "import.sh"]
