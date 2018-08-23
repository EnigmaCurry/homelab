#!/bin/sh
# Make Data Dirs
mkdir -p ${HOST}/${CONFDIR} ${HOST}/${WORKDIR}

# Copy Config
#cp -pR /etc/whatevs ${HOST}/${CONFDIR}

# Create Container
chroot ${HOST} /usr/bin/docker create -v ${WORKDIR}:/home/jovyan/work:Z --name ${NAME} ${IMAGE}

# Install systemd unit file for running container
sed -e "s/TEMPLATE/${NAME}/g" /etc/systemd/system/${NAME}.service > ${HOST}/etc/systemd/system/${NAME}.service

# Enabled systemd unit file
# chroot ${HOST} /usr/bin/systemctl enable /etc/systemd/system/${NAME}.service
