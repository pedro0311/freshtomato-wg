FROM debian:10

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install --no-install-suggests --no-install-recommends -y \
  apt-utils \
  libnss-wrapper \
  && apt-get install --no-install-suggests --no-install-recommends -y \
  build-essential \
  net-tools \
  autoconf \
  m4 \
  bison \
  flex \
  g++ \
  libtool \
  sqlite \
  gcc \
  binutils \
  patch \
  bzip2 \
  make \
  gettext \
  unzip \
  zlib1g-dev \
  libc6 \
  gperf \
  automake \
  groff \
  lib32stdc++6 \
  libncurses5 \
  libncurses5-dev \
  gawk \
  gitk \
  zlib1g-dev \
  autopoint \
  shtool \
  autogen \
  mtd-utils \
  gcc-multilib \
  gconf-editor \
  lib32z1-dev \
  pkg-config \
  libssl-dev \
  automake1.11 \
  libmnl-dev \
  libxml2-dev \
  intltool \
  libglib2.0-dev \
  libstdc++5 \
  texinfo \
  dos2unix \
  xsltproc \
  libnfnetlink0 \
  libcurl4-openssl-dev \
  libgtk2.0-dev \
  libnotify-dev \
  libevent-dev \
  git \
  re2c \
  texlive \
  libelf1 \
  nodejs \
  zip \
  mc \
  cmake \
  curl \
  libfl-dev \
  ninja-build \
  wget \
  util-linux \
  bsdmainutils \
  autoconf-archive \
  && dpkg --add-architecture i386 \
  && apt-get update \
  && apt-get install --no-install-suggests --no-install-recommends -y \
  libelf1:i386 \
  libelf-dev:i386 \
  && apt-get remove -y 'libicu-dev*' 'uuid-dev*' \
  && rm -rf /var/lib/apt/lists/*

COPY nss_wrapper /usr/bin/

# Map user and dont run as root
USER 65534
ENTRYPOINT ["nss_wrapper"]
CMD ["bash"]
