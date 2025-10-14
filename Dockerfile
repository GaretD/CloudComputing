# Use the official Nginx image from docker.io as the base image
FROM docker.io/library/nginx

# Copy the custom index.html file into the Nginx web directory
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80, the default Nginx port
EXPOSE 80
