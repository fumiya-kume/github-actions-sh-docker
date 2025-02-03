FROM ubuntu

# Install necessary dependencies, including jq for JSON parsing
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    git \
    sudo \
    jq \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# Create the runner directory and add a non-root runner user
RUN mkdir /home/runner && groupadd -r runner && useradd -r -g runner runner
WORKDIR /home/runner

# Set runner version (can be overridden with --build-arg)
ARG RUNNER_VERSION=2.300.0

# Download and extract the GitHub Actions runner
RUN curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L \
    https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Copy the entrypoint script (which now displays a help message for invalid arguments) and mark it as executable
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Switch to the non-root runner user
USER runner

# Set the entrypoint using a relative path since WORKDIR is already set
ENTRYPOINT ["./entrypoint.sh"]
