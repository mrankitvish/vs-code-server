# VS Code Server on Kubernetes with Docker-in-Docker

This project provides a pre-configured Helm chart to deploy a powerful, web-based VS Code environment directly onto your Kubernetes cluster. It comes equipped with essential development tools and Docker-in-Docker (DIND) capabilities, allowing you to code, build, and run containerized applications all from your browser.

## What is this?

This is a self-contained VS Code environment, running as a set of pods in your Kubernetes cluster. It's designed for developers who want a consistent, powerful, and accessible coding environment without needing to install VS Code or development tools locally.

**Key Features:**

*   **Full VS Code Experience:** Access a familiar VS Code interface, complete with support for extensions, themes, and settings synchronization (via persistent storage).
*   **Pre-installed Development Tools:** No need to manually install common tools. This environment includes:
    *   **Git:** For version control.
    *   **Vim:** A powerful text editor.
    *   **cURL & wget:** For transferring data.
    *   **htop & tree:** For system monitoring and directory viewing.
    *   **build-essential:** For compiling C/C++ programs.
    *   **Python3 venv & pip:** For Python development.
    *   **Node.js & npm:** For JavaScript/Node.js development.
*   **Docker-in-Docker (DIND):** Run Docker commands, build images, and manage containers directly from the VS Code terminal. This is perfect for developing and testing containerized applications.
*   **Secure Access:** The web interface is secured with SSL/TLS, ensuring your connection is encrypted.
*   **Persistent Storage:** Your code, VS Code settings, and installed extensions are saved in a persistent volume, so you won't lose your work when the pod restarts.

## What Do You Need? (Prerequisites)

Before you can deploy this VS Code environment, you'll need a few things set up:

1.  **A Running Kubernetes Cluster:**
    *   This could be a local cluster like **Minikube** or **Docker Desktop (with Kubernetes enabled)**.
    *   Or a cloud-based cluster like **Google Kubernetes Engine (GKE)**, **Amazon EKS**, or **Azure AKS**.
    *   You need administrative access to this cluster to deploy applications.

2.  **`kubectl` Command-Line Tool:**
    *   This is the primary tool for interacting with your Kubernetes cluster.
    *   It must be installed and configured to connect to your cluster. You can verify this by running `kubectl get nodes` and seeing your cluster's nodes listed.

3.  **Helm 3 Package Manager:**
    *   Helm is used to install and manage Kubernetes applications (called "charts").
    *   This project is distributed as a Helm chart. You can install Helm by following the instructions on the [official Helm website](https://helm.sh/docs/intro/install/).

4.  **SSL/TLS Certificates:**
    *   To securely access the VS Code web interface, you need an SSL certificate.
    *   **For Production/Public Use:** It's highly recommended to use certificates from a trusted Certificate Authority (CA) like **Let's Encrypt**. You can obtain these for free using tools like Certbot.
    *   **For Development/Internal Use:** You can generate self-signed certificates. Your browser will show a security warning, but you can proceed safely for development purposes. (See "Step 2: Get Your SSL Certificates" below for a quick guide on generating self-signed certs).

## How to Use It (Quick Start Guide)

Follow these steps to get your VS Code environment running.

### Step 1: Get the Helm Chart

**Clone the repository:**
```bash
git clone https://github.com/mrankitvish/vs-code-server.git
cd vs-code-server
```
### Step 2: Get Your SSL Certificates

You need two files: `fullchain.pem` (your certificate) and `privkey.pem` (your private key).

**Option A: Using Let's Encrypt (Recommended for Public Access)**
If you have a domain name pointing to your cluster, use Certbot to get a certificate:
```bash
# Follow Certbot instructions for your setup. Example for standalone mode:
sudo certbot certonly --standalone -d your-vs-code-domain.com
# Your certificates will be in /etc/letsencrypt/live/your-vs-code-domain.com/
```

**Option B: Generating Self-Signed Certificates (For Development)**
If you don't have a domain or are just testing, you can generate your own:
```bash
# Generate a private key
openssl genrsa -out privkey.pem 2048

# Generate a self-signed certificate
# When prompted for "Common Name", enter the IP address or domain you'll use to access VS Code.
openssl req -new -x509 -key privkey.pem -out fullchain.pem -days 365
```
You will now have `privkey.pem` and `fullchain.pem` in your current directory.

### Step 3: Create a Kubernetes TLS Secret

Kubernetes needs your SSL certificate and key in a special "Secret" object. Create it using `kubectl`:

```bash
# Make sure you are in the directory where your privkey.pem and fullchain.pem are located
kubectl create secret tls code-server-tls-secret \
  --cert=./fullchain.pem \
  --key=./privkey.pem \
  --namespace default # Use the namespace where you plan to deploy
```
*   `code-server-tls-secret`: This is the name of the secret. You can change it, but you'll need to update the Helm values accordingly.
*   `--namespace default`: Deploy the secret in the `default` namespace. Change this if you're using a different namespace.

### Step 4: Deploy
Run the following command from your terminal.
```bash 
helm install my-vs-code ./Chart  --set namespace=default
```

### Step 5: Access Your VS Code Environment

Once the deployment is complete (you can check with `kubectl get pods -n default`), find the URL to access VS Code.

**If you used `serviceType: NodePort` (e.g., on Minikube):**

Minikube makes this easy:
```bash
minikube service my-vs-code-release-service --namespace default --url
```
This command will output the direct URL (IP and port) to open in your browser.

**If you used `serviceType: LoadBalancer` (e.g., on GKE/EKS/AKS):**

Get the external IP address:
```bash
kubectl get service code-ser --namespace default
```
Wait for the `EXTERNAL-IP` field to be populated (this might take a few minutes). Then, navigate to `https://<EXTERNAL-IP>:<NodePort>` in your browser. (The NodePort will be shown in the service output, e.g., `8443:31234/TCP` means the NodePort is `31234`).

**Login:**
Open the provided URL in your browser. You'll likely see a browser security warning about the self-signed certificate (if you used one). Click "Advanced" and "Proceed to...". You will be prompted for the password you set in `my-values.yaml`.

## How to Use Docker Inside VS Code

Once you're logged in, open the integrated terminal in VS Code (`Terminal` -> `New Terminal`). You can now run Docker commands directly:

```bash
# Check Docker version
docker --version

# Pull an image
docker pull nginx:latest

# Run a container
docker run -d -p 8080:80 --name my-nginx nginx:latest

# See running containers
docker ps

# Access your Nginx container (see "Accessing Apps Inside the Pod" below)
```

## Accessing Applications You Run Inside the Pod

If you run a web server (like the Nginx example above on port 8080 inside the container) inside your VS Code pod, you'll need a way to access it from your local machine's browser.

The easiest way is with `kubectl port-forward`:

1.  **Find your VS Code pod name:**
    ```bash
    kubectl get pods -n default -l app=code-server
    ```
    It will look something like `my-vs-code-xxxxxxxx-abcde`.

2.  **Forward a local port to the pod's port:**
    This example forwards your local port `8080` to port `8080` inside the pod where your application is running.
    ```bash
    kubectl port-forward <your-vs-code-pod-name> 8080:8080 -n default
    ```
    Keep this command running in a separate terminal.

3.  **Access your application:**
    Now, open your browser and go to `http://localhost:8080`.

## Need Help?

*   **Check Pod Status:** If VS Code isn't loading, check if the pod is running: `kubectl get pods -n default`. If it's failing, describe the pod for more details: `kubectl describe pod <pod-name> -n default`.
*   **Check Logs:** View the logs of the code-server container: `kubectl logs <pod-name> -c code-server -n default`.
*   **Review Configuration:** Double-check your `my-values.yaml` file, especially the `password` and `tlsSecretName`.

## Cleanup

To remove the VS Code environment from your cluster:
```bash
helm uninstall my-vs-code --namespace default
```
If you also want to delete the persistent data (your code and settings):
```bash
kubectl delete pvc <pvc-name> --namespace default
# Find the PVC name with: kubectl get pvc -n default
```
And to delete the TLS secret:
```bash
kubectl delete secret code-server-tls-secret --namespace default