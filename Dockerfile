FROM ubuntu:18.04
LABEL maintainer="Pupil Labs <info@pupil-labs.com>"

# NOTE: Docker ignores lines with comments when parsing, so we can put comments inbetween code.

# set apt to noninteractive for skipping user input
ENV DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
# add venv to path (mostly for python/pip compatibility instead of python3/pip3)
# add installed python to path
ENV PATH=/.venv/bin:/python/bin:$PATH
# for finding libuvc shared library
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# NOTE: Squashing all setups into a single RUN command.
# This makes startup of the container much quicker, since it's only a single layer.
# Building takes much longer though, because docker can't cache anything.
# When debugging, put a couple of RUN's inbetween for utilizing the cache.

RUN \
# ========== install apt dependencies ==========
	# install build deps for python 3.6
	apt-get update && \
	apt-get install -y software-properties-common && \
	add-apt-repository -s 'deb http://archive.ubuntu.com/ubuntu/ bionic main' && \
	apt-get update && \
	apt-get build-dep -y python3.6 && \
	# other depdencies
	apt-get install -y \
		pkg-config \
		git \
		cmake \
		build-essential \
		nasm \
		wget \
		python3-setuptools \
		libusb-1.0-0-dev \
		python3-dev \
		python3-pip \
		python3-numpy \
		python3-scipy \
		libglew-dev \
		libglfw3-dev \
		libtbb-dev \
		libavformat-dev \
		libavcodec-dev \
		libavdevice-dev \
		libavutil-dev \
		libswscale-dev \
		libavresample-dev \
		ffmpeg \
		x264 \
		x265 \
		libportaudio2 \
		portaudio19-dev \
		python3-opencv \
		libopencv-dev \
	&& \
# ========== install python ==========
	# download and build python 3.6.9 source
	wget https://www.python.org/ftp/python/3.6.9/Python-3.6.9.tgz && \
	tar -xzf Python-3.6.9.tgz && \
	cd Python-3.6.9 && \
	./configure --prefix=/python/ && \
	make -j8 && \
	make install && \
	# cleanup
	cd .. && \
	rm -rf Python-3.6.9* && \
	# create a venv so we have python/pip instead of python3/pip3 for consistency with our setup scripts
	# see ENV section above, the venv is added to the path!
	python3 -m venv /.venv && \
	# update pip for all of your new setupscripts to work correctly
	python -m pip install -U pip && \
# ========== install turbojpeg ==========
	wget -O libjpeg-turbo.tar.gz https://sourceforge.net/projects/libjpeg-turbo/files/1.5.1/libjpeg-turbo-1.5.1.tar.gz/download && \
	tar xvzf libjpeg-turbo.tar.gz && \
	cd libjpeg-turbo-1.5.1 && \
	./configure --enable-static=no --prefix=/usr/local && \
	make install && \
	ldconfig && \
	# cleanup
	cd .. && \
	rm -rf libjpeg-turbo* && \
# ========== install libuvc ==========
	git clone https://github.com/pupil-labs/libuvc && \
	cd libuvc && \
	mkdir build && \
	cd build && \
	cmake .. && \
	make && \
	make install && \
	# cleanup
	cd ../.. && \
	rm -rf libuvc && \
# ========== install python libraries with pip ==========
	pip install \
		cysignals \
		cython \
		msgpack==0.5.6 \
		numexpr \
		opencv-python \
		packaging \
		psutil \
		pupil_apriltags \
		pyaudio \
		pyopengl \
		git+https://github.com/zeromq/pyre \
		pyzmq \
		scipy \
		torch \
		torchvision \
	&& \
	# note: install these separately since some packages have setup-requires which need to be installed already
	pip install \
		git+https://github.com/pupil-labs/PyAV \
		git+https://github.com/pupil-labs/pyndsi \
		git+https://github.com/pupil-labs/pyglui \
		git+https://github.com/pupil-labs/nslr \
		git+https://github.com/pupil-labs/nslr-hmm \
		git+https://github.com/pupil-labs/pyuvc \
	&& \
# ========== cleanup docker image ==========
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
