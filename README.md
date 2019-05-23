# Regional Tileserver


This repo contains install and import scripts to host a regional part of a vector tile server backed by Openstreetmap
data, currently used by the StreetComplete App.


# Warning


currently only tested on a Debian Testing (Debian Buster) Server

# Setup


copy settings.sh.example to settings.sh and change if needed

install dependencies, database user and some needed files:

    ./install_deps.sh

Copy and modify systemd file:

    sudo cp tileserver-gunicorn@.service /etc/systemd/system/
    sudo vim /etc/systemd/system/tileserver-gunicorn@.service
    sudo systemctl daemon-reload

# Configure



add a User to the Database:

    sudo -u postgres psql
    create user osm with encrypted password 'mypass';
    CREATE DATABASE osm OWNER osm;

(The osm database is used to connect to do rename the database for production, )



add the Postgress password to the settings.sh


Tuning the Database configs: TODO (incrase memory in various places)

# Import Database



the default port used will be 8001. (see ../workdir/port_mapping)

* Select a region the tileserver should serve (Ask @Akasch for infos)
* start the import inside of a screen/temux session because it wil propably take a loong time 
* start import:

    ./import_data.sh <tile>

for example:

    sudo ./import_data.sh 6_30_22


This will download the data and import it. This will need up to 3 days on a HDD if the region .pbf file is ~1,5 GB.
After the import a configuration is written and the systemd unit is started and enabled. It will listen on the next
port not defined in port_mapping. There will be some SQL errors in the middel about columns not found, this is normal
and expected (migrations which are not needed).

To integrate it into the global tileserver expose the port to the internet (best with nginx or apache as reverse proxy
in front of it) and ping @Akasch.


# Update Data


Currently the used data is sliced at most once per week. To reimport the data just rerun the import command. This will
import the data into a second Database (defaults to <tile>_b) and switch them at the end so the old data gets served until
the import finishes. 

The reimport.sh script will import all installed regions. so you can add this script to the (root) crontab

**Warning:** This will need the database size (of the biggest region) a second time during import!

