
FROM nginx:alpine

LABEL description="Automated Student Placement Portal"

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
