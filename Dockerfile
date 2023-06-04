FROM debian:stable

RUN dpkg --add-architecture arm64
RUN apt update
RUN apt install -y git build-essential \
    zlib1g-dev ninja-build binutils-aarch64-linux-gnu gcc-aarch64-linux-gnu \
    libglib2.0-dev:arm64 libfdt-dev:arm64 libpixman-1-dev:arm64 zlib1g-dev:arm64\
    python2.7 checkinstall

# RUN useradd user --create-home --home-dir /home/user --shell /bin/bash --uid 1000
# USER user
RUN mkdir /usr/local/var
RUN mkdir /usr/local/libexec

WORKDIR /qemu
CMD ./configure --target-list=aarch64-softmmu --disable-werror \
    --python=`which python2.7` --cross-prefix=aarch64-linux-gnu- && \
    make -j$(nproc) && \
    checkinstall -D --install=no -y --pkgname qemu-sekvm --pkgversion 0.0.1 -A arm64
