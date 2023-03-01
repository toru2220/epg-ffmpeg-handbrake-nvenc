# handbrake
FROM jrottenberg/ffmpeg:5.1.2-nvidia2004 AS handbrake

WORKDIR /tmp

RUN apt update && \
    apt install -y autoconf automake autopoint appstream build-essential cmake git libass-dev libbz2-dev libfontconfig1-dev libfreetype6-dev libfribidi-dev libharfbuzz-dev libjansson-dev liblzma-dev libmp3lame-dev libnuma-dev libogg-dev libopus-dev libsamplerate-dev libspeex-dev libtheora-dev libtool libtool-bin libturbojpeg0-dev libvorbis-dev libx264-dev libxml2-dev libvpx-dev m4 make meson nasm ninja-build patch pkg-config tar zlib1g-dev clang

RUN git clone https://github.com/HandBrake/HandBrake.git && cd HandBrake && \
    ./configure --enable-nvenc --launch-jobs=$(nproc) --launch --disable-gtk && \
    make --directory=build install

FROM jrottenberg/ffmpeg:5.1.2-nvidia2004

ENV NODE_VERSION 16
ENV DEBIAN_FRONTEND=noninteractive
ENV RUNTIME="lsdvd libasound2 libass9 libvdpau1 libva-x11-2 libva-drm2 libxcb-shm0 libxcb-xfixes0 libxcb-shape0 libvorbisenc2 libtheora0 libx264-155 libx265-179 libmp3lame0 libopus0 libvpx6 libaribb24-0 autoconf automake autopoint appstream build-essential cmake git libass-dev libbz2-dev libfontconfig1-dev libfreetype6-dev libfribidi-dev libharfbuzz-dev libjansson-dev liblzma-dev libmp3lame-dev libnuma-dev libogg-dev libopus-dev libsamplerate-dev libspeex-dev libtheora-dev libtool libtool-bin libturbojpeg0-dev libvorbis-dev libx264-dev libxml2-dev libvpx-dev m4 make meson nasm ninja-build patch pkg-config tar zlib1g-dev clang"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt update && \
    apt install -y wget gcc g++ make && \
    wget https://deb.nodesource.com/setup_${NODE_VERSION}.x -O - | bash - && \
    apt -y install nodejs && \
    apt install -y $RUNTIME && \
    apt purge -y wget gcc g++ make

COPY --from=l3tnun/epgstation:master-debian /app /app/
COPY --from=l3tnun/epgstation:master-debian /app/client /app/client/
COPY --from=handbrake /tmp/HandBrake/build/ /usr/local/bin/
COPY config/ /app/config
RUN chmod 444 /app/src -R

# RUN apt update && \
#     apt install -y autoconf automake autopoint appstream build-essential cmake git libass-dev libbz2-dev libfontconfig1-dev libfreetype6-dev libfribidi-dev libharfbuzz-dev libjansson-dev liblzma-dev libmp3lame-dev libnuma-dev libogg-dev libopus-dev libsamplerate-dev libspeex-dev libtheora-dev libtool libtool-bin libturbojpeg0-dev libvorbis-dev libx264-dev libxml2-dev libvpx-dev m4 make meson nasm ninja-build patch pkg-config tar zlib1g-dev clang

# RUN git clone https://github.com/HandBrake/HandBrake.git && cd HandBrake && \
#     ./configure --enable-nvenc --launch-jobs=$(nproc) --launch --disable-gtk && \
#     make --directory=build install

RUN mkdir /script
COPY ffmpeg.sh /script
COPY handbrake.sh /script
RUN chmod +x /script/*.sh
# dry run
RUN ffmpeg -codecs 
RUN HandBrakeCLI --help

LABEL maintainer="maleicacid"
EXPOSE 8888 8889
WORKDIR /app
ENTRYPOINT ["npm"]
CMD ["start"]

