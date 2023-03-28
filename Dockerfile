# FROM ubuntu:22.10
FROM python:3.12.0a1

WORKDIR /app

ARG firefox_ver=106.0.5
ARG geckodriver_ver=0.32.0
ARG build_rev=0

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends --no-install-suggests \
            ca-certificates python3-pip build-essential chrpath libssl-dev libxft-dev xvfb libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev wget bzip2 libxtst6 libgtk-3-0 libx11-xcb-dev libdbus-glib-1-2 libxt6 libpci-dev\
 && update-ca-certificates \
    \
 # Install tools for building
 && toolDeps=" \
        curl bzip2 \
    " \
 && apt-get install -y --no-install-recommends --no-install-suggests \
            $toolDeps \
    \
 # Install dependencies for Firefox
 && apt-get install -y --no-install-recommends --no-install-suggests \
            `apt-cache depends firefox-esr | awk '/Depends:/{print$2}'` \
            # additional 'firefox-esl' dependencies which is not in 'depends' list
            libasound2 libxt6 libxtst6 \
    \
 # Download and install Firefox
 && curl -kfL -o /tmp/firefox.tar.bz2 \
         https://ftp.mozilla.org/pub/firefox/releases/${firefox_ver}/linux-x86_64/en-GB/firefox-${firefox_ver}.tar.bz2 \
 && tar -xjf /tmp/firefox.tar.bz2 -C /tmp/ \
 && mv /tmp/firefox /opt/firefox \
    \
 # Download and install geckodriver
 && curl -kfL -o /tmp/geckodriver.tar.gz \
         https://github.com/mozilla/geckodriver/releases/download/v${geckodriver_ver}/geckodriver-v${geckodriver_ver}-linux64.tar.gz \
 && tar -xzf /tmp/geckodriver.tar.gz -C /tmp/ \
 && chmod +x /tmp/geckodriver \
 && mv /tmp/geckodriver /usr/local/bin/ \
    \
 # Cleanup unnecessary stuff
 && apt-get purge -y --auto-remove \
                  -o APT::AutoRemove::RecommendsImportant=false \
            $toolDeps \
 && rm -rf /var/lib/apt/lists/* \
           /tmp/*

RUN pip install --upgrade pip \
    && pip install prometheus-client python-dateutil requests python-dateutil selenium==4.1.0 beautifulsoup4 PyVirtualDisplay && chmod +x /opt/firefox/firefox

    
ENV MOZ_HEADLESS=1
ENV PATH="$PATH:/opt/firefox"

COPY cert_exporter.py /app

CMD ["python3", "salicru_exporter.py"]