#!/usr/bin/env bash

for server in `cat server_list`; do
    ./import_data.sh ${server}
done


