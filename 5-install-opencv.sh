#!/bin/bash
# Define OpenCV Version to install 
OpenCV_Version="3.4.4"
echo "script to create install openCV"
echo "    -A - apt-get required packages for openCV, only needs to be done once"
echo "    -D - Download openCV and prepare the Makefile, only necessary if not already on your SDCard"
echo "    -B - Build openCV, only necessary if not already on your SDCard"
echo "    -I - Install openCV into the system area of the eMMC"
echo "The entire process takes just over 2 hours on db820c"
# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
apt=0
download=0
build=0
install=0

while getopts "v:ADBI" opt; do
    case "$opt" in
    A)  apt=1
        ;;
    D)  download=1
        ;;
    B)  build=1
        ;;
    I)  install=1
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

echo "apt=$apt, download=$download, install=$install, Leftovers: $@"
# Save current working directory
cwd=$(pwd)

#libjasper1 doesn't seem to be available for arm64 Debian, so we
#fetch and build libjasper
if [ ! -d jasper ]; then
mkdir jasper
	echo fetching and building jasper
	cd jasper
	wget  http://www.ece.uvic.ca/~frodo/jasper/software/jasper-2.0.14.tar.gz 
	tar -vzxf  jasper-2.0.14.tar.gz 
	cd jasper-2.0.14
	mkdir BUILD
	cd BUILD
	cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DCMAKE_SKIP_INSTALL_RPATH=YES -DCMAKE_INSTALL_DOCDIR=/usr/share/doc/jasper-2.0.14 ..  
	make
	sudo make install
	cd ../../..
fi

if [ $apt = 1 ]; then
	## Install dependencies
	sudo apt -y install build-essential cmake pkg-config yasm
	sudo apt -y install git gfortran
	sudo apt -y install libpng-dev libjpeg62-turbo-dev
	sudo apt -y install software-properties-common
	sudo apt -y install libtiff-dev libqt5opengl5-dev
	sudo apt -y install libavcodec-dev libavformat-dev libswscale-dev
	sudo apt -y install libxine2-dev libv4l-dev libdc1394-22-dev
#	cd /usr/include/linux
#	sudo ln -s -f ../libv4l1-videodev.h videodev.h
#	cd "$cwd"

	sudo apt -y install libgtk2.0-dev libtbb-dev qt5-default
	sudo apt -y install libatlas-base-dev
	sudo apt -y install libfaac-dev libmp3lame-dev libtheora-dev
	sudo apt -y install libvorbis-dev libxvidcore-dev
	sudo apt -y install libopencore-amrnb-dev libopencore-amrwb-dev
	sudo apt -y install libavresample-dev
	sudo apt -y install x264 v4l-utils
	sudo apt -y install libeigen3-dev 

	# opengl and vtk
	sudo apt-get install -y freeglut3-dev libglew-dev libglm-dev
	sudo apt-get install -y libvtk7-qt-dev python3-vtk7 mesa-common-dev

	# now install python3 libraries
	sudo apt -y install python3-scipy python3-matplotlib python3-skimage python3-ipython

	# Optional dependencies
	sudo apt -y install libprotobuf-dev protobuf-compiler
	sudo apt -y install libgoogle-glog-dev libgflags-dev
	sudo apt -y install libgphoto2-dev libeigen3-dev libhdf5-dev doxygen
	sudo apt -y install python3-dev python3-pip python3-tk python3-numpy
	sudo apt -y install python3-testresources python3-venv
fi


if [ $download = 1 ]; then
	cd $cwd
	git clone https://github.com/opencv/opencv.git
	cd opencv
	git checkout "$OpenCV_Version"
	cd ..

	#currently we are not building and installing the contrib stuff
	git clone https://github.com/opencv/opencv_contrib.git
	cd opencv_contrib
	git checkout "$OpenCV_Version"
	cd ..

	cd opencv
	mkdir build
	cd build

	cmake -DWITH_LIBV4L=ON \
	      -DWITH_QT=ON \
	      -DCMAKE_POLICY_DEFAULT_CMP0072=NEW \
	      -DCMAKE_BUILD_TYPE=RELEASE \
	      -DWITH_OPENGL=ON \
	      -DWITH_VTK=OFF \
	      -DBUILD_opencv_viz=OFF \
	      -DWITH_TBB=ON \
	      -DWITH_GDAL=ON \
	      -DWITH_XINE=ON \
	      -DBUILD_EXAMPLES=ON \
	      -DWITH_OPENMP=ON \
	      -DWITH_GSTREAMER=ON \
	      -DWITH_OPENCL=ON ..

fi
if [ $build = 1 ]; then
	cd "$cwd"
	cd opencv/build
	echo Building openCV
	make -j4
	cd "$cwd"
fi
if [ $install = 1 ]; then
	cd "$cwd"
	if [ ! -d /usr/include/jasper ]; then
		cd jasper/jasper-2.0.14/BUILD
		sudo make install
		cd "$cwd"
	fi
	# now install python3 libraries
	cd opencv/build
	echo Installing openCV
	make -j4
	sudo make install
	# link the module so Python3.7 can find it.
	if [ -f /usr/local/python/cv2/python-3.7/cv2.so ]; then
		sudo rm /usr/local/python/cv2/python-3.7/cv2.so
	fi
	cd /usr/local/python/cv2/python-3.7
	sudo ln cv2.cpython-37m-aarch64-linux-gnu.so cv2.so
	cd "$cwd"
	# and some other bits we need
	time sudo pip3 install imutils
fi
