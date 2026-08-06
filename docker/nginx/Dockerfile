# =============================================================================
# docker/nginx/Dockerfile — Nexoraa CleanSoft Nginx Image
# =============================================================================
FROM nginx:1.27-alpine

# Remove default Nginx config
RUN rm -f /etc/nginx/conf.d/default.conf

# Copy custom reverse proxy config
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf

# Create log directory with correct permissions
RUN mkdir -p /var/log/nginx \
    && chown -R nginx:nginx /var/log/nginx \
    && chmod 750 /var/log/nginx

# Health check — verify nginx config is valid and process responds
HEALTHCHECK \
    --interval=30s \
    --timeout=5s \
    --start-period=10s \
    --retries=3 \
    CMD wget -qO- http://localhost/api/v1/health/live > /dev/null 2>&1 || exit 1

EXPOSE 80 443
