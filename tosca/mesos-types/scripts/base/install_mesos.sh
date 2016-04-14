#!/bin/bash

echo "Installing Mesos Base into directory $(pwd) on distrib ${OS_DISTR}"
echo "Adding Mesosphere package repository.."
case ${OS_DISTR} in
    "debian"|"ubuntu")

        LINUX_CODENAME=$(lsb_release -cs)

        NAME="Mesos Base"
        LOCK="/tmp/lockaptget"

        while true; do
            if mkdir "${LOCK}" &>/dev/null; then
              echo "$NAME take apt lock"
              break;
            fi
            echo "$NAME waiting apt lock to be released..."
            sleep 0.5
        done

        while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
            echo "$NAME waiting for other software managers to finish..."
            sleep 0.5
        done
        sudo rm -f /var/lib/dpkg/lock

        # Setup package repo
        sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv E56151BF
        echo "deb http://repos.mesosphere.com/${OS_DISTR} ${LINUX_CODENAME} main" | sudo tee /etc/apt/sources.list.d/mesosphere.list
        sudo apt-get -y update || (sleep 15; sudo apt-get update || exit $1)

        # Install Mesos - ZK is pulled as a dependency
        if [ $MESOS_VERSION ]; then
            pkg="${MESOS_VERSION}.${OS_DISTR}$(echo ${OS_VERS} | tr -d '.')"
            if apt-cache show mesos=$pkg -q >/dev/null 2>&1; then
                echo "Installing Mesos version $pkg"
                sudo apt-get -y install mesos=${pkg} || exit 1
            else
                echo "Unknown Mesos version $pkg - Installing latest version"
                sudo apt-get -y install mesos || exit 1
            fi
        else
            echo "Installing latest Mesos version"
            sudo apt-get -y install mesos || exit 1
        fi

        rm -rf "${LOCK}"
        echo "$NAME released apt lock"
        ;;
    "redhat"|"centos")
        if [ "${OS_VERS}" -ge "7" ]; then
            # Add the repository
            sudo rpm -Uvh http://repos.mesosphere.com/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm
        elif [ "${OS_VERS}" -ge "6" ] && [ "${OS_VERS}" -lt "7" ]; then
            # Add mesos and zookeeper repositories
            sudo rpm -Uvh http://repos.mesosphere.com/el/6/noarch/RPMS/mesosphere-el-repo-6-2.noarch.rpm
            sudo rpm -Uvh http://archive.cloudera.com/cdh4/one-click-install/redhat/6/x86_64/cloudera-cdh-4-0.x86_64.rpm

            # Install ZK
            sudo yum -y install zookeeper
        else
            echo "Unsupported version ${OS_VERS} of ${OS_DISTR}. Exiting now..."
            exit 1
        fi

        # Install Mesos
        if [ ${MESOS_VERSION} ]; then
            pkg="${MESOS_VERSION}.${OS_DISTR}$(echo ${OS_VERS} | tr -d '.')"
            if yum info mesos=$pkg -q >/dev/null 2>&1; then
                echo "Installing Mesos version $pkg"
                sudo yum -y install mesos=${pkg} || exit 1
            else
                echo "Unknown Mesos version $pkg - Installing latest version"
                sudo yum -y install mesos || exit 1
            fi
        else
            echo "Installing latest Mesos version"
            sudo yum -y install mesos || exit 1
        fi

        ;;
    *)
        echo "${OS_DISTR} is not supported ATM. Exiting..."
        exit 1
        ;;
esac

echo "Stopping mesosphere services"
# Stop services from running - if they are
( sudo service mesos-master status | grep 'running' ) && sudo service master-stop stop
( sudo service mesos-slave status | grep 'running' ) && sudo service mesos-slave stop
( sudo service zookeeper status | grep 'running' ) && sudo service zookeeper stop

# Prevent services from being run upon reboot
if { [ ${OS_DISTR} = 'redhat' ] || [ ${OS_DISTR} = 'centos' ]; } && [ ${OS_VERS} -ge 7 ]; then
    systemctl disable mesos-slave.service
    systemctl disable mesos-master.service
    systemctl disable zookeeper.service
else
    echo "manual" | sudo tee /etc/init/mesos-master.override >/dev/null
    echo "manual" | sudo tee /etc/init/mesos-slave.override >/dev/null
    echo "manual" | sudo tee /etc/init/zookeeper.override >/dev/null
fi

exit 0