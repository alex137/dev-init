# syntax=docker/dockerfile:1

# STAGE 1: Haskell & Clash Builder
FROM mcr.microsoft.com/devcontainers/base:trixie AS haskell-builder
USER root
RUN apt-get update && apt-get install -y \
    curl \
    binutils-gold \
    xz-utils \
    build-essential \
    libtinfo-dev \
    libncurses-dev \
    && ln -sf /usr/bin/ld.gold /usr/bin/ld \
    && rm -rf /var/lib/apt/lists/*

ENV GHCUP_INSTALL_SKIP_MSYS=1
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | \
    BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_GHC_VERSION=9.6.4 \
    BOOTSTRAP_HASKELL_CABAL_VERSION=3.10.2.1 \
    sh

ENV PATH="/root/.ghcup/bin:/root/.cabal/bin:${PATH}"
# Using a cache mount to speed up subsequent Haskell package downloads

# Inside Stage 1 (haskell-builder)
RUN --mount=type=cache,target=/root/.cabal/packages \
    cabal update && \
    cabal install --lib clash-prelude --overwrite-policy=always && \
    cabal install clash-ghc --overwrite-policy=always --jobs=1 && \
    # CRITICAL: Clean up temporary GHCup files before ending the layer
    rm -rf /root/.ghcup/tmp/* && \
    rm -rf /root/.ghcup/logs/*

# STAGE 2: Final Dev Environment
FROM mcr.microsoft.com/devcontainers/base:trixie
USER root

# 1. System Essentials (Stable layers first)
RUN apt-get update && apt-get install -y \
    curl git xz-utils openssh-server gnupg build-essential \
    python3 python3-pip clang llvm gdb nasm cmake unzip zip \
    verilator yosys ghdl iverilog gtkwave graphviz \
    && rm -rf /var/lib/apt/lists/*

# 2. Copy Haskell/Clash from the builder stage
# This is "Shielded" - it only updates if Stage 1 changes
COPY --from=haskell-builder /root/.ghcup /root/.ghcup
COPY --from=haskell-builder /root/.cabal /root/.cabal
COPY --from=haskell-builder /usr/bin/ld.gold /usr/bin/ld.gold
RUN ln -sf /usr/bin/ld.gold /usr/bin/ld
ENV PATH="/root/.ghcup/bin:/root/.cabal/bin:${PATH}"

# 3. Rust, Elixir, & Gleam (Stable binaries)
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN apt-get update && apt-get install -y elixir erlang-dev && \
    RAW_ARCH=$(uname -m) && \
    ARCH_MAP=$([ "$RAW_ARCH" = "aarch64" ] && echo "aarch64" || echo "x86_64") && \
    GLEAM_URL="https://github.com/gleam-lang/gleam/releases/download/v1.8.1/gleam-v1.8.1-${ARCH_MAP}-unknown-linux-musl.tar.gz" && \
    curl -fsSL "$GLEAM_URL" | tar -xzC /usr/local/bin && \
    chmod +x /usr/local/bin/gleam && rm -rf /var/lib/apt/lists/*

# 4. Node.js & Claude (Likely to change more often)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs && npm install -g @anthropic-ai/claude-code


# 5. Create Generic Non-Root User (Dynamic - Bottom)
ARG USERNAME=user
RUN if getent group 1000; then groupmod -n $USERNAME $(getent group 1000 | cut -d: -f1); else groupadd --gid 1000 $USERNAME; fi && \
    if getent passwd 1000; then usermod -l $USERNAME -m -d /home/$USERNAME $(getent passwd 1000 | cut -d: -f1); else useradd --uid 1000 --gid 1000 -m $USERNAME; fi && \
    echo "$USERNAME:password" | chpasswd && \
    apt-get update && apt-get install -y sudo && \
    echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    rm -rf /var/lib/apt/lists/*

# 6. SSH Config (Always Bottom)
RUN mkdir -p /var/run/sshd && echo "root:zed" | chpasswd && \
    sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/" /etc/ssh/sshd_config && \
    sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/" /etc/ssh/sshd_config



# Set the starting directory for all shells and tools
WORKDIR /workspaces/repo

# Ensure the 'user' owns this directory to avoid permission issues
RUN chown -R user:user /workspaces/repo


USER root

# Ensure the sshd directory exists and keys are generated
RUN mkdir -p /var/run/sshd && \
    ssh-keygen -A && \
    chmod 600 /etc/ssh/ssh_host_*_key

EXPOSE 22

# 7. Entrypoint for persistent home directory
COPY .devcontainer/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

USER root
CMD ["/usr/sbin/sshd", "-D"]
