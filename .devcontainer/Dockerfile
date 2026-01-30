# syntax=docker/dockerfile:1
#
# Main dev environment - references pre-built Haskell image
# Run: make build-master (fast, uses cached Haskell)
# To rebuild Haskell: make build-haskell (slow, only when needed)

FROM mcr.microsoft.com/devcontainers/base:trixie@sha256:0fea8c4b6512d8bb1a1419efb9cd0e6585a7a91d76c1cd44494a27849ef730fe
USER root

# 1. System Essentials
RUN apt-get update && apt-get install -y \
    curl git xz-utils openssh-server gnupg build-essential \
    python3 python3-pip clang llvm gdb nasm cmake unzip zip \
    verilator yosys ghdl iverilog gtkwave graphviz \
    inotify-tools pandoc texlive-full \
    fonts-noto-core fonts-noto-mono fonts-noto-cjk \
    fonts-dejavu-core fonts-dejavu-extra \
    fonts-liberation fonts-liberation2 \
    fonts-freefont-ttf fonts-roboto fonts-lato fonts-open-sans \
    fonts-firacode fonts-hack fonts-inconsolata fonts-cascadia-code \
    fonts-ubuntu fonts-font-awesome \
    && rm -rf /var/lib/apt/lists/*

# 2. Copy Haskell/Clash from pre-built image (run 'make build-haskell' first)
COPY --from=dev-env-haskell:latest /root/.ghcup /root/.ghcup
COPY --from=dev-env-haskell:latest /root/.cabal /root/.cabal
COPY --from=dev-env-haskell:latest /usr/bin/ld.gold /usr/bin/ld.gold
RUN ln -sf /usr/bin/ld.gold /usr/bin/ld
ENV PATH="/root/.ghcup/bin:/root/.cabal/bin:${PATH}"

# 3. Rust, Elixir, & Gleam
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN apt-get update && apt-get install -y elixir erlang-dev && \
    RAW_ARCH=$(uname -m) && \
    ARCH_MAP=$([ "$RAW_ARCH" = "aarch64" ] && echo "aarch64" || echo "x86_64") && \
    GLEAM_URL="https://github.com/gleam-lang/gleam/releases/download/v1.8.1/gleam-v1.8.1-${ARCH_MAP}-unknown-linux-musl.tar.gz" && \
    curl -fsSL "$GLEAM_URL" | tar -xzC /usr/local/bin && \
    chmod +x /usr/local/bin/gleam && rm -rf /var/lib/apt/lists/*

# 4. Node.js & Claude
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g @anthropic-ai/claude-code @marp-team/marp-cli

# 4a. Claude secure wrapper - nukes credentials after auth
COPY .devcontainer/claude-secure.sh /usr/local/bin/claude-secure
RUN chmod +x /usr/local/bin/claude-secure && \
    CLAUDE_PATH=$(which claude) && \
    mv "$CLAUDE_PATH" "${CLAUDE_PATH}.real" && \
    ln -sf /usr/local/bin/claude-secure "$CLAUDE_PATH"

# 5. Create Non-Root User
ARG USERNAME=user
RUN if getent group 1000; then groupmod -n $USERNAME $(getent group 1000 | cut -d: -f1); else groupadd --gid 1000 $USERNAME; fi && \
    if getent passwd 1000; then usermod -l $USERNAME -m -d /home/$USERNAME $(getent passwd 1000 | cut -d: -f1); else useradd --uid 1000 --gid 1000 -m $USERNAME; fi && \
    passwd -l $USERNAME && \
    apt-get update && apt-get install -y sudo && \
    echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    rm -rf /var/lib/apt/lists/*

# 6. Configure npm for user-writable global installs
RUN mkdir -p /home/$USERNAME/.npm-global && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME/.npm-global && \
    su - $USERNAME -c "npm config set prefix '/home/$USERNAME/.npm-global'"
ENV PATH="/home/user/.npm-global/bin:${PATH}"

# 7. SSH Config - Key-based auth only
RUN mkdir -p /var/run/sshd && passwd -l root && \
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config && \
    mkdir -p /home/$USERNAME/.ssh && chmod 700 /home/$USERNAME/.ssh && chown $USERNAME:$USERNAME /home/$USERNAME/.ssh

WORKDIR /workspaces/repo
RUN chown -R user:user /workspaces/repo

USER root
RUN mkdir -p /var/run/sshd && \
    ssh-keygen -A && \
    chmod 600 /etc/ssh/ssh_host_*_key

EXPOSE 22

COPY .devcontainer/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

USER root
CMD ["/usr/sbin/sshd", "-D"]
