# Copyright (c) 2016 Jorge Aparicio
# https://github.com/japaric/cross
set -ex

main() {
    if [ "$(uname)" != "Linux" ]; then
        exit 0
    fi

    local version=1.0.2m
    local os=$1 \
          triple=$2
    local m_version=1.1.15

    local dependencies=(
        ca-certificates
        curl
        m4
        make
        perl
        pkg-config
        g++
    )


    # NOTE cross toolchain must be already installed
    apt-get update
    local purge_list=()
    for dep in ${dependencies[@]}; do
        if ! dpkg -L $dep; then
            apt-get install --no-install-recommends -y $dep
            purge_list+=( $dep )
        fi
    done

    local td=$(mktemp -d)

    pushd $td
    curl https://www.musl-libc.org/releases/musl-$m_version.tar.gz | \
        tar --strip-components=1 -xz

    CFLAGS="-fPIC ${@:3}" ./configure \
          --disable-shared \
          --prefix=/usr/local \
          $(test -z $target || echo --target=$target)
    nice make -j$(nproc)
    nice make install
    ln -s /usr/bin/ar /usr/local/bin/musl-ar

    popd

    td=$(mktemp -d)

    pushd $td
    curl https://www.openssl.org/source/openssl-$version.tar.gz | \
        tar --strip-components=1 -xz
    AR=${triple}ar CC=${triple}gcc ./Configure \
      --prefix=/openssl \
      no-dso \
      $os \
      -fPIC \
      ${@:3}
    nice make -j$(nproc)
    make install
}

main "${@}"
