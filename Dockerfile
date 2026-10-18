# Auth gateway for the Firecrawl API; config in Caddyfile.
FROM caddy:2.11.7-alpine
COPY Caddyfile /etc/caddy/Caddyfile
