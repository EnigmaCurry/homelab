FROM jupyter/scipy-notebook as base
USER root
RUN apt-get update && apt-get install -y git ssh ansible pwgen

FROM base as jupyter_ansible
MAINTAINER Ryan McGuire <ryan@enigmacurry.com>

CMD ["start.sh", "jupyter", "lab"]
