#! /bin/bash

. settings.sh


tile=$1
. ${workdir}/port_mapping
PORT=${PORTS[${tile}]}

. ${workdir}/version_mapping
VERSION=${VERSIONS[${tile}]}

pyenv="${workdir}/.pyenv-${VERSION}"
source ${pyenv}
${pyenv}/bin/gunicorn -w 2 -t 120 -b 0.0.0.0:${PORT} "tileserver:wsgi_server('config.${tile}.yaml')"
