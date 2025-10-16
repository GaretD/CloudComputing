How the workflow works

    Checkout repository: This action retrieves your code from the GitHub repository.
    Build Podman image: The podman build . -t my-nginx-image command executes the instructions in your Dockerfile to create a new image named my-nginx-image.
    Run Podman container: The podman run command starts a new container from your custom image.
        -d runs the container in the background.
        -p 8080:80 maps port 8080 on the host to port 80 inside the container.
        --name my-nginx-container assigns a name to the container for easy reference.
    Verify Nginx is serving the page: This step uses curl to send a web request to localhost:8080 and checks for the "Hello, Podman!" text, confirming your custom index.html is being served correctly. 


How to run from your local machine:
1. Authenticate to the registry:
Log in to GitHub Container Registry
podman login ghcr.io -u <YOUR_GITHUB_USERNAME> -p <YOUR_PERSONAL_ACCESS_TOKEN>

2. Pull the image:
podman pull ghcr.io/<YOUR_GITHUB_USERNAME>/<REPOSITORY_NAME>/my-nginx-image:<GIT_SHA>

3. Run the container:
podman run -d -p 8080:80 my-nginx-image