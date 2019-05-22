#! /bin/bash

. settings.sh

if hash apt-get 2>/dev/null; then
    echo "Using apt-get to install"
    sudo apt-get install git python-virtualenv osm2pgsl python-pip python-dev gcc postgis
elif hash dfn 2>/dev/null; then
    echo "Using DFN to install"
    sudo dnf install osm2pgsql python2-virtualenv git python2-pip python2-devel postgis gcc
else
    echo "Unknown package manager"
    exit 1
fi

sudo adduser tileserver --home ${homedir} --system


sudo mkdir ${workdir}
cd ${workdir}

# todo: add postgress account

# todo: add systemd unit file


#todo: make port configurable, the first tileserver will use this port plus 1
echo "declare -A PORTS">port_mapping
echo "PORTS[dummy]=8000">>port_mapping
touch server_list

chown -hR tileserver ~tileserver

# initial nginx frontend confi + certs???
#### maybe via subdomain from map-data.de
