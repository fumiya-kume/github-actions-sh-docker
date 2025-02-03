FROM ubuntu:20.04

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    git \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create runner directory and add non-root runner user
RUN mkdir /actions-runner && groupadd -r runner && useradd -r -g runner runner
WORKDIR /actions-runner

# Set runner version (can be overridden with --build-arg)
ARG RUNNER_VERSION=2.300.0

# Download and extract the GitHub Actions runner
RUN curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L \
    https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Copy the entrypoint script and ensure it is executable
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Switch to the non-root runner user
USER runner

# Set the entrypoint script
ENTRYPOINT ["entrypoint.sh"]
