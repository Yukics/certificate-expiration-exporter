# -*- coding: utf-8 -*-
# Prometheus-client: https://github.com/prometheus/client_python

import os
import requests
import socket
import ssl
import time
import json
import re
from prometheus_client import start_http_server, Gauge
from datetime import datetime

def get_url_array():
    # define text file to open
    my_file = open('url.txt', 'r')

    # read text file into list
    return my_file.readlines()

def get_url_info(url, port):

    ctx = ssl.create_default_context()
    with ctx.wrap_socket(socket.socket(), server_hostname=url) as s:
        s.connect((url, port))
        cert = s.getpeercert()

    #? print(json.dumps(cert,sort_keys=True, indent=4))

    return dict(x[0] for x in cert['subject'])['commonName'], dict(x[0] for x in cert['issuer'])['organizationName'], cert['notAfter'], cert['notBefore']


def parse_datetime(date_string):
    return datetime.strptime(re.sub(' +', ' ', date_string), '%b %d %H:%M:%S %Y %Z').timestamp()

class AppMetrics:

    def __init__(self, polling_interval_seconds=10):

        self.polling_interval_seconds = polling_interval_seconds

        # Prometheus metrics to collect
        self.https_cert_time_left = Gauge("https_cert_time_left", "Status of https webs", ['url', 'hostname', 'ca', 'creation_date'])

        # Get url_array
        self.url_array = get_url_array()

    def run_metrics_loop(self):
        """Metrics fetching loop"""
        while True:
            self.fetch()
            time.sleep(self.polling_interval_seconds)

    def fetch(self):
        """
        Get metrics from application and refresh Prometheus metrics with
        new values.
        """
        url_array = get_url_array()
        for url in url_array:
            try:
                hostname, ca, creation_date, expiration_date = get_url_info(url.split(":")[0], int(url.split(":")[1]))
                self.https_cert_time_left.labels(url.strip(), hostname, ca, parse_datetime(creation_date)).set(parse_datetime(expiration_date))
            except:
                print("ERROR: Couldnt retrieve {}".format(url))    

if __name__ == "__main__":
    print("Starting http-cert-exporter...")

    # Disable all cert warnings
    requests.packages.urllib3.disable_warnings()

    # Env vars set up
    exporter_port = int(os.getenv("PORT", "8980"))
    polling_interval_seconds = int(os.getenv("POLLING_INTERVAL_SECONDS", "10"))

    app_metrics = AppMetrics(
        polling_interval_seconds=polling_interval_seconds
    )

    # Starts prometheus http server
    start_http_server(exporter_port)

    # Retrieves data
    print("http-cert-exporter up and running!")
    app_metrics.run_metrics_loop()

