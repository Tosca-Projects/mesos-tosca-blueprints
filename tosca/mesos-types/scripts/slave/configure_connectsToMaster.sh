#!/bin/bash

# Add the MASTER_URL (eg. the zookeeper endpoint for mesos : zk://master1:2181,master2:2181,.../mesos)
if [ -n "${MESOS_MASTER}" ]; then
    url=$(echo ${MESOS_MASTER} | tr " " ",") # TODO: This is to workaround the replacement of commas with spaces when the output is exported
    echo "export MESOS_MASTER=\"${url}\"" >> ~/mesos_install/mesos_env.sh
else
    >&2 echo "Failed to configure slave : Master URL is mandatory." && exit 1
fi
