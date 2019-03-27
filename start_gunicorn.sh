#! /bin/bash

tile=$1
. ../port_mapping
PORT=${PORTS[${tile}]}

/opt/tileserver/workdir/.pyenv/bin/gunicorn -w 2 -t 120 -b 0.0.0.0:${PORT} "tileserver:wsgi_server('config.${tile}.yaml')"
