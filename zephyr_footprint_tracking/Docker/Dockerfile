FROM debian:11

RUN apt-get update && apt-get install -y python3-pip git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt requirements.txt

RUN python3 -m pip install -r requirements.txt

RUN mkdir -p /data/zephyr

RUN mkdir -p /data/footprint_data

COPY check.py check.py

COPY import.sh import.sh

COPY upload_data.py upload_data.py

CMD [ "/bin/bash", "import.sh"]
