# FROM jrottenberg/ffmpeg:5.1.2-nvidia2004
FROM ghcr.io/toru2220/epgstation-nvenc-docker:main

ENV NODE_VERSION 16
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y autoconf automake autopoint appstream build-essential cmake git libass-dev libbz2-dev libfontconfig1-dev libfreetype6-dev libfribidi-dev libharfbuzz-dev libjansson-dev liblzma-dev libmp3lame-dev libnuma-dev libogg-dev libopus-dev libsamplerate-dev libspeex-dev libtheora-dev libtool libtool-bin libturbojpeg0-dev libvorbis-dev libx264-dev libxml2-dev libvpx-dev m4 make meson nasm ninja-build patch pkg-config tar zlib1g-dev clang

RUN git clone https://github.com/HandBrake/HandBrake.git && cd HandBrake && \
    ./configure --enable-nvenc --launch-jobs=$(nproc) --launch --disable-gtk && \
    make --directory=build install

RUN mkdir -p /script
RUN mkdir -p /patched-lib
COPY ffmpeg.sh /script
COPY handbrake.sh /script
COPY patch.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/patch.sh /script/ffmpeg.sh /script/handbrake.sh

# dry run
RUN ffmpeg -codecs 
RUN HandBrakeCLI --help

EXPOSE 8888 8889
WORKDIR /app

COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

ENTRYPOINT ["/app/docker-entrypoint.sh"]

