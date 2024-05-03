# Homelab Docker

This respository contains the Docker Compose files for some of my self-hosted apps that are running in Docker containers. 

## Overview

It leverages [Renovate](https://github.com/renovatebot/renovate) for automated dependency management and includes a simple continuous deployment (CD) script for pulling updates.

Script (meant to run as a cron job) checks for changes in the Docker Compose files pushed to the repository and automatically pulls the changes and redeploys the affected services using `docker compose up -d`.

## Alternatives

* What about [Portainer](https://github.com/portainer/portainer)? Portainer Business Edition does [gitops](https://www.portainer.io/gitops-automation), but downside is that it costs money (and further reliance on Portainer).
* What about [Watchtower](https://github.com/containrrr/watchtower)? Watchtower only works if the image tag is `latest`, and it checks for updates against a container image repo directly (e.g., DockerHub), not against Docker Compose files in a git repo.

