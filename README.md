# github-actions-sh-docker

# How to pull
```docker pull ghcr.io/fumiya-kume/github-actions-sh-docker/github-actions-runner:latest```

```
docker run -d \
     -e RUNNER_TOKEN=your_runner_token \
     -e RUNNER_URL=https://github.com/your_org_or_repo \
     -e RUNNER_NAME=your_runner_name \
     github-actions-runner
```
