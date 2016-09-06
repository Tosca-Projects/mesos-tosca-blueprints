#!/bin/bash -e

# Prepare a sh script to export mesos environment variables
mkdir -p ~/mesos_install
touch ~/mesos_install/mesos_env.sh
while IFS='=' read name value; do
  if [ -n "$value" ]; then
    echo "export ${name}=\"${value}\"" >> ~/mesos_install/mesos_env.sh
  fi
done < <(env | grep "^MESOS_")

# Install rexray
curl -sSL https://dl.bintray.com/emccode/rexray/install | sudo sh -s -- stable 0.3.3
sudo cp ${rexray_config} /etc/rexray/config.yml

# Add ports resources for LB --resources=ports:[9090-9091,10000-101000,31000-32000]
echo "export MESOS_RESOURCES=\"ports:[53,8123,9090-9091,10000-101000,31000-32000]\"" >> ~/mesos_install/mesos_env.sh
