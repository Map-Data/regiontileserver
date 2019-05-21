#!/usr/bin/env bash

for server in `cat server_list`; do
    ./inport_data.sh ${server}
done


