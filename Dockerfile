FROM python:3.12.0a1

WORKDIR /app

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends --no-install-suggests \
            ca-certificates python3-pip build-essential chrpath libssl-dev libxft-dev xvfb libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev wget bzip2 libxtst6 libgtk-3-0 libx11-xcb-dev libdbus-glib-1-2 libxt6 libpci-dev\
 && update-ca-certificates 

RUN pip install --upgrade --trusted-host pypi.org --trusted-host files.pythonhosted.org pip \
    && pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org prometheus-client python-dateutil requests python-dateutil

COPY cert_exporter.py /app

CMD ["python3", "cert_exporter.py"]