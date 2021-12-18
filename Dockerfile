ARG RESTIC_VERSION=0.12.1

####################################################################################################
## Final image
####################################################################################################
FROM alpine:3.15

ARG RESTIC_VERSION

ENV RESTIC_REPOSITORY="/mnt/restic" \
    RESTIC_PASSWORD_FILE="/run/secrets/restic.key" \
    B2_ACCOUNT_ID="" \
    B2_ACCOUNT_KEY="" \
    BACKUP_CRON="" \
    RESTIC_JOB_ARGS="" \
    MAILX_ARGS=""

RUN apk add --no-cache \
    ca-certificates \
    curl \
    bzip2 \
    tini \
    heirloom-mailx \
    fuse

WORKDIR /

ADD https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_amd64.bz2 /tmp/restic.bz2
RUN bzip2 -d /tmp/restic.bz2; \
    cp /tmp/restic /usr/local/bin/restic; \
    chmod +x /usr/local/bin/restic

# Create directory structure
RUN mkdir -p /mnt/restic \
    && mkdir -p /var/spool/cron/crontabs \
    && mkdir -p /var/log \
    && touch /var/log/cron.log

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
COPY ./backup.sh /bin/backup

RUN chmod +x docker-entrypoint.sh \
    && chmod +x /bin/backup

ENTRYPOINT ["/sbin/tini", "--", "/docker-entrypoint.sh"]

CMD ["tail", "-fn0", "/var/log/cron.log"]

VOLUME /data

STOPSIGNAL SIGTERM

# Image metadata
LABEL org.opencontainers.image.version=${RESTIC_VERSION}
LABEL org.opencontainers.image.title=restic
LABEL org.opencontainers.image.description="restic is a backup program that is fast, efficient and secure."
LABEL org.opencontainers.image.vendor="Silkky.Cloud"
LABEL org.opencontainers.image.licenses=Unlicense
LABEL org.opencontainers.image.source="https://github.com/silkkycloud/docker-restic"