FROM mcr.microsoft.com/devcontainers/python:1-3.12-bookworm

USER root
RUN apt-get update && apt-get install -y \
    curl git openssh-server gnupg build-essential \
    clang llvm gdb nasm cmake unzip zip \
    verilator yosys ghdl iverilog gtkwave graphviz \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Elide (JS, TS, Python, Kotlin)
RUN curl -sSL --tlsv1.2 https://elide.sh | bash -s -
ENV PATH="/root/.elide/bin:${PATH}"

# Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Elixir & Gleam
RUN apt-get update && apt-get install -y elixir erlang-dev \
    && curl -fsSL https://github.com/gleam-lang/gleam/releases/latest/download/gleam-nightly-x86_64-unknown-linux-musl.tar.gz | tar -xzC /usr/local/bin \
    && rm -rf /var/lib/apt/lists/*

# Haskell
RUN apt-get update && apt-get install -y ghc cabal-install && rm -rf /var/lib/apt/lists/*
ENV PATH="/root/.cabal/bin:${PATH}"

# Haskel Clash
RUN cabal update && \
    cabal install --lib clash-prelude && \
    cabal install clash-ghc --overwrite-policy=always

#Claude
RUN npm install -g @anthropic-ai/claude-code

# SSH for Zed
RUN mkdir -p /var/run/sshd && \
    echo "vscode:zed" | chpasswd && \
    sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/" /etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
