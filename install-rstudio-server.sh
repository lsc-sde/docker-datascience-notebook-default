#!/bin/bash

if [ "$TARGETARCH" = "amd64" ]; then
    echo "Installing rstudio-server"
    export FILE_NAME="rstudio-server-${RSTUDIO_VERSION}-${TARGETARCH}.deb"
    export RSTUDIO_URL="https://download2.rstudio.org/server/jammy/${TARGETARCH}/${FILE_NAME}"
    echo "${RSTUDIO_URL}" 
    curl -fOL ${RSTUDIO_URL} 
    gdebi -n ${FILE_NAME} 
    rm ${FILE_NAME} 
    # chown -R ${NB_USER} /var/log/rstudio-server \
    # chown -R ${NB_USER} /var/lib/rstudio-server \
    echo server-user=${NB_USER} > /etc/rstudio/rserver.conf
else
    echo "Install of rstudio-server is being skipped because the architecture is ${TARGETARCH}, not amd64"
fi
