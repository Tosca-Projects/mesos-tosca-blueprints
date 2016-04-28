#!/bin/bash -e

# Retrieves Aurora configuration and sed values into /etc/defaulf/aurora-scheduler, the configuration file used by the init.d aurora services
while IFS='=' read name value; do
    # Check if value is not null or empty
    if [ -n "$value" ]; then
        # NOTE: Workaround commas being replaced by whitespaces
        value=$(echo $value | tr " " ",")
        # Substitute value in aurora config file
        sudo sed -i.bak "s;^${name}=.*;${name}=\"${value}\";" /etc/default/aurora-scheduler
    fi
done < <(env | grep '^AURORA_' | sed 's/AURORA_//')

# Calculate quorum
quorum=$((1 + $(echo $INSTANCES | tr "," " " | wc -w)/2))
sudo sed -i.bak "s/^QUORUM_SIZE=[0-9]*/QUORUM_SIZE=${quorum}/" /etc/default/aurora-scheduler