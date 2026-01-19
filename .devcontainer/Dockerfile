FROM mcr.microsoft.com/devcontainers/base:trixie

USER root

# 1. System Essentials & Hardware Tools
RUN apt-get update && apt-get install -y \
    curl git xz-utils \
    openssh-server gnupg build-essential \
    python3 python3-pip \
    clang llvm gdb nasm cmake unzip zip \
    verilator yosys ghdl iverilog gtkwave graphviz \
    && rm -rf /var/lib/apt/lists/*

# 2. Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# 3. Elide (High-performance Polyglot Runtime)
RUN curl -sSL https://elide.sh | bash -s -- --yes && \
    mkdir -p /root/.elide/bin && \
    mv /root/elide/elide /root/.elide/bin/elide
ENV PATH="/root/.elide/bin:${PATH}"

# 4. Rust Toolchain
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"


# 5. Elixir & Gleam
RUN apt-get update && apt-get install -y elixir erlang-dev && \
    RAW_ARCH=$(uname -m) && \
    if [ "$RAW_ARCH" = "aarch64" ]; then \
        GLEAM_URL="https://github.com/gleam-lang/gleam/releases/download/v1.8.1/gleam-v1.8.1-aarch64-unknown-linux-musl.tar.gz"; \
    else \
        GLEAM_URL="https://github.com/gleam-lang/gleam/releases/download/v1.8.1/gleam-v1.8.1-x86_64-unknown-linux-musl.tar.gz"; \
    fi && \
    echo "🏗️ Downloading Gleam from: $GLEAM_URL" && \
    curl -fsSL "$GLEAM_URL" | tar -xzC /usr/local/bin && \
    chmod +x /usr/local/bin/gleam && \
    rm -rf /var/lib/apt/lists/*


# 6. Haskell & Clash (The ARM Linker Fix)
RUN apt-get update && apt-get install -y binutils-gold && \
    ln -sf /usr/bin/ld.gold /usr/bin/ld && \
    rm -rf /var/lib/apt/lists/*

ENV GHCUP_INSTALL_SKIP_MSYS=1
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | \
    BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_GHC_VERSION=9.6.4 \
    BOOTSTRAP_HASKELL_CABAL_VERSION=3.10.2.1 \
    sh
ENV PATH="/root/.ghcup/bin:/root/.cabal/bin:${PATH}"

RUN cabal update && \
    cabal install --lib clash-prelude --overwrite-policy=always && \
    cabal install clash-ghc --overwrite-policy=always --jobs=1 && \
    rm -rf /root/.cabal/packages

# 7. Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# 8. SSH Configuration for Zed
RUN mkdir -p /var/run/sshd && \
    echo "root:zed" | chpasswd && \
    sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/" /etc/ssh/sshd_config && \
    sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/" /etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
