FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        ffmpeg \
        jq \
        motion \
        msmtp \
        msmtp-mta \
        procps \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --uid 1000 --create-home --shell /usr/sbin/nologin barley \
    && mkdir -p /recordings /www/api /var/lib/motion \
    && chown -R barley:barley /recordings /www/api /var/lib/motion

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENV HOME=/home/barley
EXPOSE 8081
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["motion", "-n", "-c", "/etc/motion/motion.conf"]
