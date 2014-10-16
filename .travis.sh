#!/bin/bash

case "$1" in
  before_install)
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
    sudo sh -c 'echo "deb http://get.docker.io/ubuntu docker main" > /etc/apt/sources.list.d/docker.list'
    sudo apt-get update

    echo "exit 101" | sudo tee /usr/sbin/policy-rc.d
    sudo chmod +x /usr/sbin/policy-rc.d

    sudo apt-get install -qy slirp lxc lxc-docker socat

    git clone git://github.com/spotify/sekexe

    ;;

  before_script)
    export HOST_IP=`/sbin/ifconfig venet0:0 | grep 'inet addr' | awk -F: '{print $2}' | awk '{print $1}'`
    export DOCKER_HOST=tcp://$HOST_IP:2375
    export SLIRP_PORTS=`seq 2375 2375`

    VERBOSE=1 sekexe/run "docker -d -H tcp://0.0.0.0:2375" &

    if [ $UNIX_SOCKETS == "yes" ]
    then
      socat UNIX-LISTEN:/tmp/docker.sock,fork TCP4:$HOST_IP:2375 &
      export DOCKER_HOST=unix:///tmp/docker.sock
    fi

    while ! docker info; do sleep 1; done

    ;;

esac
