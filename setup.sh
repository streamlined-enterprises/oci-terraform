exit 0

sudo dnf update -y
# Install Docker: use dnf for Oracle Linux
sudo dnf install -y dnf-utils zip unzip
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
# Start and Enable Docker Service
sudo systemctl start docker
sudo systemctl enable docker
# Add the 'opc' user to the 'docker' group to run commands without 'sudo'
sudo usermod -aG docker opc
echo 'Docker installed successfully.'
# NOTE: The 'opc' user needs a new session for the 'usermod' change to take effect.
# This is tricky in a single remote-exec run. We will rely on the fact that
# Docker is now installed. The easiest self-hosted way is running the server via Docker.
echo 'Pulling and running OpenHands container...'
# This command pulls the image and runs the OpenHands GUI on port 3000
# You need to open port 3000 in your OCI Network Security Group!
docker pull ghcr.io/all-hands-ai/openhands:latest
docker run -d --name openhands-server -p 3000:3000 -v /var/run/docker.sock:/var/run/docker.sock ghcr.io/all-hands-ai/openhands:latest serve
