#!/bin/bash
echo "script to create install dlib"
echo "    -A - apt-get required packages for dlib, only needs to be done once"
echo "    -I - Install dlib into the system area of the eMMC"

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
apt=0
install=0

while getopts "v:AI" opt; do
    case "$opt" in
    A)  apt=1
        ;;
    I)  install=1
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

echo "apt=$apt, download=$download, install=$install, Leftovers: $@"

if [ $apt = 1 ]; then
	# install the required packages for dlib
	sudo apt-get install -y build-essential cmake
	sudo apt-get install -y libopenblas-dev liblapack-dev
#	sudo apt-get install -y libx11-dev libgtk-3-dev
	sudo apt-get install -y python3 python3-dev python3-pip
fi

if [ $install = 1 ]; then
	if [ ! -d pip ]; then
		mkdir pip
	fi
	#pip by default builds in ~/.cache, we want to build in ./dlib
	echo building dlib this takes about 45 minutes
	time sudo pip3 --cache-dir /usr/linaro/workspace/db820c/pip install dlib
fi
