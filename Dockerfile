FROM openresty/openresty:bullseye-fat

COPY ./lua /app
COPY ./openresty/nginx/conf.d /etc/nginx/conf.d

EXPOSE 8080
