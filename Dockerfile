FROM nginx:1.30.6-alpine

ARG APP_VERSION=dev
ARG VCS_REF=local

LABEL org.opencontainers.image.title="devops-diploma-app" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.source="https://github.com/sarkroge/devops-diploma-app"

COPY nginx.conf /etc/nginx/nginx.conf
COPY html/ /usr/share/nginx/html/

RUN rm -f /etc/nginx/conf.d/default.conf \
    && mkdir -p /tmp/nginx \
    && chown nginx:nginx /tmp/nginx \
    && printf '{"version":"%s"}\n' "$APP_VERSION" > /usr/share/nginx/html/version.json

USER nginx
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O - http://127.0.0.1:8080/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]
