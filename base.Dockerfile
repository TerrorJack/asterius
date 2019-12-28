FROM debian:sid

ARG DEBIAN_FRONTEND=noninteractive

ENV \
  ASTERIUS_LIB_DIR=/home/asterius/.asterius-local-install-root/share/x86_64-linux-ghc-8.6.5/asterius-0.0.1/.boot/asterius_lib \
  LANG=C.UTF-8 \
  LC_ALL=C.UTF-8 \
  LC_CTYPE=C.UTF-8 \
  PATH=/home/asterius/.asterius-local-install-root/bin:/home/asterius/.asterius-snapshot-install-root/bin:/home/asterius/.asterius-compiler-bin:/home/asterius/.local/bin:${PATH}

RUN \
  apt update && \
  apt full-upgrade -y && \
  apt install -y \
    automake \
    cmake \
    curl \
    g++ \
    gawk \
    gcc \
    git \
    gnupg \
    libffi-dev \
    libgmp-dev \
    libncurses-dev \
    libnuma-dev \
    make \
    python3 \
    xz-utils \
    zlib1g-dev && \
  curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
  echo "deb https://deb.nodesource.com/node_13.x sid main" > /etc/apt/sources.list.d/nodesource.list && \
  apt update && \
  apt install -y nodejs && \
  useradd --create-home --shell /bin/bash asterius

USER asterius

WORKDIR /home/asterius

RUN \
  mkdir -p ~/.local/bin && \
  curl -L https://get.haskellstack.org/stable/linux-x86_64.tar.gz | tar xz --wildcards --strip-components=1 -C ~/.local/bin '*/stack' && \
  curl -L https://downloads.haskell.org/~cabal/cabal-install-2.4.1.0/cabal-install-2.4.1.0-x86_64-unknown-linux.tar.xz | tar xJ -C ~/.local/bin 'cabal' && \
  mkdir -p ~/.asterius/inline-js

COPY --chown=asterius:asterius asterius /home/asterius/.asterius/asterius
COPY --chown=asterius:asterius binaryen /home/asterius/.asterius/binaryen
COPY --chown=asterius:asterius ghc-toolkit /home/asterius/.asterius/ghc-toolkit
COPY --chown=asterius:asterius inline-js/inline-js-core /home/asterius/.asterius/inline-js/inline-js-core
COPY --chown=asterius:asterius npm-utils /home/asterius/.asterius/npm-utils
COPY --chown=asterius:asterius wabt /home/asterius/.asterius/wabt
COPY --chown=asterius:asterius wasm-toolkit /home/asterius/.asterius/wasm-toolkit
COPY --chown=asterius:asterius stack.yaml /home/asterius/.asterius/stack.yaml

RUN \
  export CPUS=$(getconf _NPROCESSORS_ONLN 2>/dev/null) && \
  export MAKEFLAGS=-j$CPUS && \
  cd ~/.asterius && \
  stack --no-terminal build \
    asterius \
    binaryen \
    wabt \
    alex \
    happy \
    c2hs \
    cpphs && \
  ln -s $(stack path --local-install-root) ~/.asterius-local-install-root && \
  ln -s $(stack path --snapshot-install-root) ~/.asterius-snapshot-install-root && \
  ln -s $(stack path --compiler-bin) ~/.asterius-compiler-bin && \
  ahc-boot

USER root

RUN \
  apt purge -y \
    automake \
    cmake \
    curl \
    g++ \
    git \
    gnupg \
    make \
    mawk \
    python3 \
    xz-utils && \
  apt autoremove --purge -y && \
  apt clean && \
  mv \
    /home/asterius/.asterius-local-install-root/bin \
    /home/asterius/.asterius-local-install-root/share \
    /tmp && \
  rm -rf \
    /home/asterius/.asterius \
    /home/asterius/.asterius-compiler-bin/../share \
    /home/asterius/.cabal \
    /home/asterius/.config \
    /home/asterius/.local/bin/stack \
    /home/asterius/.npm \
    /home/asterius/.stack/programs/*/*.tar.xz \
    /var/lib/apt/lists/* \
    /var/tmp/* && \
  mkdir -p $(realpath -m /home/asterius/.asterius-local-install-root) && \
  mv \
    /tmp/bin \
    /tmp/share \
    /home/asterius/.asterius-local-install-root && \
  mv \
    /home/asterius/.asterius-snapshot-install-root/bin \
    /home/asterius/.asterius-snapshot-install-root/share \
    /home/asterius/.stack/programs \
    /tmp && \
  rm -rf /home/asterius/.stack && \
  mkdir -p $(realpath -m /home/asterius/.asterius-snapshot-install-root) && \
  mv \
    /tmp/bin \
    /tmp/share \
    /home/asterius/.asterius-snapshot-install-root && \
  mv \
    /tmp/programs \
    /home/asterius/.stack && \
  chown -c -h -R asterius:asterius /home/asterius && \
  rm -rf \
    /tmp/*

USER asterius

RUN \
  ahc --version && \
  alex --version && \
  cabal --version && \
  node --version && \
  wasm-objdump --version && \
  wasm-opt --version
