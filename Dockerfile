FROM nginx:alpine

LABEL maintainer="rabetsara"
LABEL description="TP DevOps - Jenkins + Trivy Security Scan"

# Page HTML simple
RUN echo '<html><body><h1>TP DevOps - Jenkins Pipeline OK</h1></body></html>' \
    > /usr/share/nginx/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
