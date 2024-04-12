# New Python 3.11 data science notebook for LANDER
# Work in progress - started on 2023-09-09
# az acr build --registry crlander -f Dockerfile -t v2/datascience-cinnamon-code:2023-09-25 .
# Provides the following IDEs
# - JupyterLab
# - RStudio Server
# - Code Server
# - XCFE Linux Desktop

# https://hub.docker.com/r/jupyter/datascience-notebook/tags/
ARG OWNER=lscsde
ARG BASE_CONTAINER=jupyter/datascience-notebook:2023-09-25
FROM $BASE_CONTAINER
ARG TARGETOS TARGETARCH
LABEL maintainer="lscsde"
LABEL image="datascience-notebook-default"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Install essentials for code-server
# Install XFCE and essential desktop tools
RUN apt-get update --yes
RUN apt-get upgrade --yes
RUN apt-get install --yes --quiet --no-install-recommends \
  # ubuntu-mate-desktop \
  build-essential \
  clang \
  cmake \
  curl \
  g++ \
  htop \
  iputils-ping \
  libopencv-dev \
  make \
  # XCFE Desktop
  dbus-x11 \
  libgl1-mesa-glx \
  xfce4 \
  xfce4-panel \
  xfce4-session \
  xfce4-settings \
  xorg \
  xubuntu-icon-theme \
  # Office suite
  gnumeric \
  abiword

RUN apt-get remove --yes --quiet light-locker
RUN apt-get autoremove --yes --quiet
RUN apt-get clean --quiet
RUN rm -rf /var/lib/apt/lists/*


# Install Code Server and extensions
# https://github.com/coder/code-server/tags

ARG CODE_VERSION=4.23.0
RUN FILE_NAME="code-server_${CODE_VERSION}_${TARGETARCH}.deb" \
  && export URL="https://github.com/coder/code-server/releases/download/v$CODE_VERSION/${FILE_NAME}" \
  && echo "${URL}" \
  && curl -fOL ${URL} \
  && dpkg -i "${FILE_NAME}" \
  && rm -f "${FILE_NAME}"

RUN code-server --install-extension charliermarsh.ruff
RUN code-server --install-extension davidanson.vscode-markdownlint
RUN code-server --install-extension ms-python.black-formatter
RUN code-server --install-extension ms-python.python
RUN code-server --install-extension ms-python.vscode-pylance
RUN code-server --install-extension njpwerner.autodocstring
RUN code-server --install-extension quarto.quarto

# Install Quarto
ARG QUARTO_VERSION=1.3.450
RUN export FILE_NAME="quarto-${QUARTO_VERSION}-linux-${TARGETARCH}.deb" \
  && export URL="https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/${FILE_NAME}" \
  && echo "${URL}" \
  && curl -fOL ${URL} \
  && dpkg -i ${FILE_NAME} \
  && rm -f ${FILE_NAME}

# Install RStudio Server
ARG RSTUDIO_VERSION=2023.09.0-463
RUN apt update
RUN apt install --yes gdebi-core
RUN export FILE_NAME="rstudio-server-${RSTUDIO_VERSION}-${TARGETARCH}.deb" \
 && export RSTUDIO_URL="https://download2.rstudio.org/server/jammy/${TARGETARCH}/${FILE_NAME}" \
 && echo "${RSTUDIO_URL}" \
 && curl -fOL ${RSTUDIO_URL} \
 && gdebi -n ${FILE_NAME} \
 && rm ${FILE_NAME}

 RUN apt-get remove --yes gdebi-core \
  && apt-get clean --quiet \
  && rm -rf /var/lib/apt/lists/*
  # &&  chown -R ${NB_USER} /var/log/rstudio-server \
  # && chown -R ${NB_USER} /var/lib/rstudio-server \
RUN echo server-user=${NB_USER} > /etc/rstudio/rserver.conf
ENV PATH=$PATH:/usr/lib/rstudio-server/bin
ENV RSESSION_PROXY_RSTUDIO_1_4=True

# Copy custom config for jupyter
COPY jupyter_notebook_config.json /etc/jupyter/jupyter_notebook_config.json

# Finally install packages from environment.yaml
COPY environment.yaml environment.yaml

# Install Python packages for proxying XFCE and code-server
RUN mamba env update --name base --file environment.yaml
RUN rm environment.yaml
RUN mamba clean --all -f -y 
RUN fix-permissions "${CONDA_DIR}"
RUN fix-permissions "/home/${NB_USER}"

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}