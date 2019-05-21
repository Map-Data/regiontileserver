#! /usr/bin/env bash
set -e
tile=$1
. settings.sh

tileserverVersion="v2.2.0"
vectorDatasourceVersion="v1.5.0"

cd ${workdir}

md5f1=""

if [[ -f ${tile}.pbf.md5 ]]; then
    md5f1=$(cat "${tile}.pbf.md5")
fi
wget -N https://map-data.de/extract/${tile}.pbf || exit 1
md5f2=$(md5sum "${tile}.pbf" | cut -d' ' -f1)
echo ${md5f2} > ${tile}.pbf.md5
if [[ "$md5f2" == "$md5f1" ]]; then
    echo "No new data"
    exit 0
fi

echo "CREATE DATABASE ${database} OWNER ${database_user} TABLESPACE ${tablespace}"| psql -Xq -p  ${database_port} -U ${database_user} -h ${dbhost}
echo "CREATE EXTENSION postgis; CREATE EXTENSION hstore;"| psql -Xq -p  ${database_port} -U ${database_user} -h ${dbhost}
if [[ ! -d vector-datasource-${vectorDatasourceVersion} ]]; then
    git clone https://github.com/mapzen/vector-datasource.git vector-datasource-${vectorDatasourceVersion}
    vector_cloned=1
fi
if [[ ! -f port_mapping ]]; then
    echo "PORT_DUMMY=6743" > port_mapping
fi
if [[ ! -d "tileserver-${tileserverVersion}" ]]; then
    git clone https://github.com/tilezen/tileserver.git tileserver-${tileserverVersion}
    tileserver_cloned=1
fi
if [[ ! -f .pyenv-${vectorDatasourceVersion}/bin/activate ]]; then
    virtualenv .pyenv-${vectorDatasourceVersion} --python python2.7
    new_venv=1
fi
source .pyenv-${vectorDatasourceVersion}/bin/activate

cd tileserver-${tileserverVersion}
git checkout ${tileserverVersion}
if [[ ! -z ${new_venv+x} ]]; then
    pip install -U -r requirements.txt
    python setup.py develop
fi

cd ../vector-datasource-${vectorDatasourceVersion}
git checkout ${vectorDatasourceVersion}

if [[ ! -z ${new_venv+x} ]]; then
    pip install -U -r requirements.txt
    python setup.py develop
fi

osm2pgsql --slim --hstore-all -C 3000 -S osm2pgsql.style -d ${database} -P ${database_port} -U ${database_user} -H ${dbhost} --number-processes 4 --flat-nodes ../flat-nodes-file  ../${tile}.pbf || exit 1

rm ../flat-nodes-file # TODO: for dynamic updating this file is needet
rm ../${tile}.pbf

cd data

if [[ ! -z ${new_venv+x} ]]; then
    python bootstrap.py
    make -f Makefile-import-data
fi
./import-shapefiles.sh | psql -Xq -d ${database} -p ${database_port} -U ${database_user} -h ${dbhost}
./perform-sql-updates.sh -d ${database} -p ${database_port} -h ${dbhost} -U ${database_user}
cd ../..


echo "DROP DATABASE \"${database_orig}\"" | psql -Xq -p  ${database_port} -U ${database_user} -h ${dbhost}
echo "ALTER DATABASE \"${database}\" RENAME TO \"${database_orig}\"" | psql -Xq -p  ${database_port} -U ${database_user} -h ${dbhost}
sed "s/dbnames: \[osm\]/dbnames: \[${database_orig}\]/" tileserver/config.yaml.sample > tileserver/config.${tile}.yaml
sed -i "s/password:/password: ${PGPASSWORD}/" tileserver/config.${tile}.yaml

if ! grep "${tile}" server_list; then
	echo ${tile} >> server_list
	mv server_list server_list.1
	cat server_list.1 | sort | uniq > server_list
	last_port=$(cut port_mapping -d '=' -s -f 2 | sort | tail -n 1)
	new_port=$((last_port+1))
	echo "PORTS[${tile}]=${new_port}" >> port_mapping
	systemctl enable tileserver-gunicorn@${tile}
    systemctl start tileserver-gunicorn@${tile}
else
    systemctl restart tileserver-gunicorn@${tile}
fi
if [[ ! -f version_mapping ]]; then
    echo "declare -A VERSIONS\n" > version_mapping
fi
mv version_mapping version_mapping.tmp
cat version_mapping.tmp | grep -v "${tile}" > version_mapping
echo "VERSIONS[${tile}]=${vectorDatasourceVersion}" >> version_mapping


echo "DONE ${tile}"

