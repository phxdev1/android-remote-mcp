FROM node:18-alpine

LABEL maintainer="MCP Server for Android Control"
LABEL description="MCP Server with Tailscale and ADB built-in"

# Install dependencies
RUN apk add --no-cache \
    bash \
    tzdata \
    curl \
    ca-certificates \
    openssh \
    openrc \
    iptables \
    ip6tables \
    unzip \
    wget \
    supervisor

# Install Tailscale
RUN apk add --no-cache tailscale

# Create app directory
WORKDIR /app

# Install Android SDK Platform Tools for ADB
RUN mkdir -p /opt/android-sdk && \
    wget -q https://dl.google.com/android/repository/platform-tools-latest-linux.zip && \
    unzip platform-tools-latest-linux.zip -d /opt/android-sdk && \
    rm platform-tools-latest-linux.zip

# Add platform-tools to PATH
ENV PATH="/opt/android-sdk/platform-tools:${PATH}"

# Verify ADB installation
RUN adb version

# Copy package.json and package-lock.json
COPY package*.json ./

# Install app dependencies
RUN npm ci --only=production

# Copy the app source code
COPY server.js ./
COPY init.sh /init.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create directories
RUN mkdir -p /app/screenshots /var/run/tailscale /var/cache/tailscale /var/lib/tailscale

# Make scripts executable
RUN chmod +x /init.sh

# Expose ports
EXPOSE 3001/tcp
EXPOSE 41641/tcp
EXPOSE 41641/udp

# Set environment variables
ENV PORT=3001
ENV DEFAULT_PHONE_IP="100.77.199.68"

# Start the services with supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]