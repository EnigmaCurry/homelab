FROM jupyter/scipy-notebook as base
USER root
RUN apt-get update && apt-get install -y git ssh ansible


FROM base as jupyter_ansible
MAINTAINER Ryan McGuire <ryan@enigmacurry.com>
ADD root /

LABEL INSTALL docker run --rm --privileged -v /:/host -e HOST=/host -e CONFDIR=/etc/\${NAME} -e WORKDIR=/var/lib/\${NAME} -e IMAGE=\${IMAGE} -e NAME=\${NAME} \${IMAGE} /bin/install.sh
LABEL UNINSTALL docker run --rm --privileged -v /:/host -e HOST=/host -e IMAGE=${IMAGE} -e NAME=${NAME} ${IMAGE} /bin/uninstall.sh

CMD ["start.sh", "jupyter", "lab"]
