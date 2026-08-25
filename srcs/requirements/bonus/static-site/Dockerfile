# requirements/bonus/static-site/Dockerfile
FROM alpine:3.20

RUN apk add --no-cache nginx

COPY conf/static.conf /etc/nginx/http.d/default.conf
COPY site/ /usr/share/nginx/html/

EXPOSE 8080

# nginx also daemonizes by default — same fix as Lesson 6
CMD ["nginx", "-g", "daemon off;"]
