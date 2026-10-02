FROM mcr.microsoft.com/devcontainers/base:noble

USER root
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       python3 build-essential procps curl file git ca-certificates unzip \
    && apt-get clean

USER vscode
ENV HOME=/home/vscode
ENV TERM=xterm-256color
WORKDIR /home/vscode

RUN sudo -n true
CMD ["/bin/bash", "--noprofile", "--norc"]
