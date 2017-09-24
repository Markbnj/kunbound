FROM alpine:latest

# Install unbound
RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
    apk add --update unbound bash bind-tools && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

# Expose udp port
EXPOSE 53/udp

WORKDIR /etc/unbound

# the default conf just forwards to google public dns
COPY etc/unbound/unbound.conf /etc/unbound/

# entry point takes care of starting up unbound
COPY sbin/entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

ENTRYPOINT ["/sbin/entrypoint.sh"]
