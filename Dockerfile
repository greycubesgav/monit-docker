ARG ALPINE_VERSION=3.22.1
FROM alpine:${ALPINE_VERSION}
LABEL maintainer="Gavin Brown <gavin.brown@greycubes.net>"

# Expose the web interface port
EXPOSE 2812
HEALTHCHECK --interval=30s --timeout=30s --start-period=15s --retries=3 CMD curl -Is http://localhost:2812 -o /dev/null || exit 1

# monit environment variables
ARG MONIT_VERSION=5.35.2
ENV MONIT_VERSION=${MONIT_VERSION}
#ENV MONIT_VERSION=5.35.2

# Add pam since binary is linked to it
RUN apk add --update linux-pam curl && rm -rf /var/cache/apk/*

# Copy over the pre-built binary
COPY src/pkgs/monit-${MONIT_VERSION}-linux-x64-musl.tar.gz /opt/pkgs/

# Unpack the binary
RUN tar -zxf /opt/pkgs/monit-${MONIT_VERSION}-linux-x64-musl.tar.gz -C /opt/
RUN ln -s /opt/monit-${MONIT_VERSION}/bin/monit /bin/monit && \
    ln -s /opt/monit-${MONIT_VERSION}/conf/monitrc /etc/monitrc && \
    install -d -m 0700 -o 1000 -g 1000 /etc/monit.d/

# Enable the web interface and allow access from anywhere
# Set the log to go to stdout
# Uncomment the include line to include configs from /etc/monit.d/
RUN sed -i -E 's/([[:space:]]*allow localhost)/#\1/' /etc/monitrc && \
    sed -i -E 's/([[:space:]]*use address localhost)/#\1/' /etc/monitrc && \
    sed -i -E 's|([[:space:]]*)set log syslog|\1set logfile /dev/stdout|' /etc/monitrc && \
    sed -i -E 's|[[:space:]]*#[[:space:]]*(include /etc/monit.d/*)|\1|' /etc/monitrc

# Copy over the support scripts
COPY src/bin/slack /bin/slack
COPY src/bin/pushover /bin/pushover

# Create a non-root user to run monit and change to that user
RUN adduser -D -u 1000 monit
USER 1000

# Run monit in the foreground (-I), batch output (-B) nad specify the config file location (-c /etc/monitrc)
ENTRYPOINT ["/bin/monit", "-I", "-B", "-v", "-c", "/etc/monitrc"]
