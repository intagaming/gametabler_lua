FROM openresty/openresty:bullseye-fat

COPY ./lua /app
COPY ./openresty/nginx/conf.d /etc/nginx/conf.d
COPY ./config /app_config
COPY ./openresty/nginx/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

EXPOSE 8080
