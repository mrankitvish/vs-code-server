# Base image
FROM codercom/code-server:4.104.3-focal

# Switch to root to install packages
USER root

# Set DEBIAN_FRONTEND=noninteractive to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install Docker CLI and other development tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash - \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && apt-get install -y \
        git \
        nodejs \
        wget \
        curl \
        vim \
        htop \
        tree \
        build-essential \
        python3 \
        python3-pip \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*

# (Optional) Install Oh My Zsh for a better terminal experience
# RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Switch back to the default 'coder' user
USER 1000

# (Optional) Set default shell to zsh if installed
# RUN chsh -s $(which zsh)