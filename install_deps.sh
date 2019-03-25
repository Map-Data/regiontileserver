#! /bin/bash

mkdir ../wordir
cd ../workdir


sudo apt install git python-virtualenv osm2pgsl python-pip python-dev gcc postgis

sudo adduser tileserver --home /opt/tileserver/ --system

# todo: add postgress account

# todo: add systemd unit file


#todo: make port configurable, the first tileserver will use this port plus 1
echo "declare -A PORTS\nPORTS[dummy]=8000">port_mapping
touch server_list


# initial nginx frontend confi + certs???
#### maybe via subdomain from map-data.de
