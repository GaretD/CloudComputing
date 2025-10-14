How the workflow works

    Checkout repository: This action retrieves your code from the GitHub repository.
    Build Podman image: The podman build . -t my-nginx-image command executes the instructions in your Dockerfile to create a new image named my-nginx-image.
    Run Podman container: The podman run command starts a new container from your custom image.
        -d runs the container in the background.
        -p 8080:80 maps port 8080 on the host to port 80 inside the container.
        --name my-nginx-container assigns a name to the container for easy reference.
    Verify Nginx is serving the page: This step uses curl to send a web request to localhost:8080 and checks for the "Hello, Podman!" text, confirming your custom index.html is being served correctly. 