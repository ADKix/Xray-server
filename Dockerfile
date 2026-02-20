ARG ALPINE=3.23.3
ARG XRAY=v26.2.6

FROM alpine:${ALPINE}
LABEL org.opencontainers.image.authors="Axl <https://github.com/ADKix>"
RUN apk add -U --no-cache 7zip openssl util-linux-misc libqrencode-tools
ARG XRAY
ARG TARGETPLATFORM
WORKDIR "/opt"
RUN if   [ "${TARGETPLATFORM}" = "linux/arm64" ] || [ "${TARGETPLATFORM}" = "linux/arm64/v8" ]; then arch=arm64-v8a; \
    elif [ "${TARGETPLATFORM}" = "linux/arm/v7" ]; then arch=arm32-v7a; \
    elif [ "${TARGETPLATFORM}" = "linux/386" ]; then arch=32; \
    elif [ "${TARGETPLATFORM}" = "linux/amd64" ]; then arch=64; fi; \
    wget -qnc "https://github.com/XTLS/Xray-core/releases/download/${XRAY}/Xray-linux-${arch}.zip" -O- | \
      unzip -p - "xray" | \
        7z -si a "xray.7z"
COPY "entrypoint.sh" "command.sh" /
ENTRYPOINT ["sh", "/entrypoint.sh"]
CMD ["sh", "/command.sh"]
ENV PORT=443
ENV SNI=google.com
RUN mkdir -p "/opt/data"
VOLUME ["/opt/data"]
EXPOSE 443
