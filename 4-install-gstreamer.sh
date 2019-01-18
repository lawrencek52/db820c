#!/bin/bash
echo "script to create install gstreamer"
echo "    -A - apt-get required packages for gstreamer, only needs to be done once"
echo "    -D - Download and build gstreamer, only necessary if not already on your SDCard"
echo "    -I - Install gstreamer into the system area of the eMMC"

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
apt=0
download=0
install=0

while getopts "v:ADI" opt; do
    case "$opt" in
    A)  apt=1
        ;;
    D)  download=1
        ;;
    I)  install=1
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

echo "apt=$apt, download=$download, install=$install, Leftovers: $@"
if [ $apt = 1 ]; then
sudo apt-get install -y fakeroot devscripts quilt
sudo apt install -y libavc1394-dev libaa1-dev libcaca-dev \
       	libcairo2-dev libdv4-dev libflac-dev libgdk-pixbuf2.0-dev \
       	libjack-dev libpng-dev libpulse-dev libshout3-dev \
	libjpeg62-turbo-dev libsoup2.4-dev libspeex-dev libtaglib-cil-dev \
       	libwavpack-dev
#	libx11-dev
sudo apt install -y libasound2-dev libcdparanoia-dev libvorbisidec-dev \
       	libvisual-0.4-dev libopus-dev libpango1.0-dev libxv-dev libvpx-dev
fi

if [ $download = 1 ]; then
	if [ ! -d gstreamer ]; then
		mkdir gstreamer
	fi
	cd gstreamer
	sudo apt-get build-dep -y gstreamer1.0-plugins-good
	apt-get source gstreamer1.0-plugins-good
	cd gst-plugins-good1.0-1.14.4
	## edit Rules
	sed -i '178a \\t--enable-v4l2-probe \\' debian/rules
	sed -i '178a \\t--without-libv4l2 \\' debian/rules
	#
	time debuild -b -uc -us
	cd ../..
fi

if [ $install = 1 ]; then
	time sudo dpkg -i gstreamer/gstreamer1.0-plugins-good_1.14.4*_arm64.deb
fi

