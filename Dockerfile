FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive

ENV PYTHONUNBUFFERED=1
ENV NODE_MAJOR=20
ENV MODELS_DIR=/workspace/models

# Install system dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    python3.9 \
    python3-pip \
    python3-dev \
    git \
    ffmpeg \
    google-perftools \
    ca-certificates \
    curl \
    gnupg \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install NodeJS
RUN mkdir -p /etc/apt/keyrings 
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list > /dev/null
RUN apt-get update && apt-get install nodejs -y

# Set working directory for installation
WORKDIR /code

# Copy requirements first for better caching
COPY ./requirements.txt /code/requirements.txt

# Debug the requirements file
RUN echo "Contents of requirements.txt:" && cat /code/requirements.txt

# Try to install with verbose output to see errors
RUN pip3 install --no-cache-dir --upgrade --pre -r /code/requirements.txt -v

# Set up non-root user
RUN useradd -m -u 1000 user

# Create app directory and set permissions
RUN mkdir -p /home/user/app
COPY --chown=user . /home/user/app

# Switch to non-root user
USER user
WORKDIR /home/user/app

# Set environment variables for the non-root user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH \
    PYTHONPATH=/home/user/app \
    PYTHONUNBUFFERED=1 \
    SYSTEM=spaces \
    LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libtcmalloc.so.4

# Make sure the script is executable
RUN if [ -f "./build-run.sh" ]; then chmod +x ./build-run.sh; fi

EXPOSE 7860

CMD ["./build-run.sh"]