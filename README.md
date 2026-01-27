
# 🛠️ Dev-Init: The Private Dev Platform

**Dev-Init** is a "Master-Base" development ecosystem. Instead of duplicating environment logic into every repository, it builds a single, high-performance **Master Image** that all your projects inherit from.

## 🔒 Security-First Design

**Dev-Init is a sandbox.** It lets you run Claude Code and install packages from the internet without giving them access to your credentials, SSH keys, or other sensitive data on your host machine.

### Why This Matters

When you run `npm install` or `pip install`, you're executing code written by strangers. In a normal setup, that code has access to:
- Your SSH keys (push to any repo you have access to)
- Your cloud credentials (`~/.aws`, `~/.gcp`)
- Your API keys and tokens
- Everything else in your home directory

**Dev-Init isolates all of this.** Code runs in a container with access only to the current project directory.

### The Git Workflow

Since credentials aren't mounted, git push/pull won't work inside the container. This is intentional. The workflow is:

1. **Claude edits files** inside the container
2. **Changes appear instantly** on your host (volume-mounted)
3. **You run git commands** on your host: `git diff`, `git commit`, `git push`

This gives you a **forced review checkpoint** - nothing leaves your machine without you seeing it first.

### Claude API Credentials

Claude Code settings and history persist between sessions, but **credentials are automatically deleted** on container startup. This prevents malicious packages from stealing your API key.

To authenticate, pass your API key as an environment variable (never written to disk):

```bash
export ANTHROPIC_API_KEY=sk-ant-...
make up
make shell
claude  # Works immediately, no login needed
```

**Security tradeoff:** The API key is in the container's environment, so code running during that session *could* access it via `process.env`. However:
- It's not persisted to disk (deleted on every startup)
- If you're worried, don't set the key when running untrusted installs:
  ```bash
  # Install packages WITHOUT the API key set
  make up && make shell
  npm install some-package
  exit

  # Then restart WITH the key for Claude work
  export ANTHROPIC_API_KEY=sk-ant-...
  make up && make shell
  claude
  ```

---

## 🏗️ The "Base Image" Philosophy

### Why do it this way?

* **One Source of Truth:** Update your toolset (Kotlin, Rust, Elixir, AI tools) in one place. All projects update automatically.
* **Instant Init:** Creating a new project takes seconds. No more 10-minute Docker builds for every new repo.
* **Disk Efficiency:** 50 projects sharing one 4GB image instead of 50 projects each having their own 4GB image (saving ~196GB of disk space).
* **Global Command Center:** Rebuild your entire platform from within any project using Zed tasks.
* **Security Isolation:** Run untrusted code without exposing your credentials.

---

## 🚀 The Global Setup (Run Once)

1. **Install:** Place the `dev-init` repo in your code directory:
```bash
~/code/
  ├── dev-init/      # The Platform Engine
  └── your-projects/ # Where your code lives

```


2. **Build the Master:** Run this inside the `dev-init` folder:
```bash
make build-master

```


*This creates the `dev-env:latest` image containing Elide, Rust, Elixir, Gleam, Haskell, and Claude CLI.*

---

## 🛠️ Project Initialization

To turn any folder into a professional dev environment, run this from that folder's root:

```bash
make -f ../dev-init/Makefile dev-init

```

**What happens?**

* A 1-line `Dockerfile` is created: `FROM dev-env:latest`.
* A `docker-compose.yml` is linked.
* The `Makefile` is synchronized.
* **Zed Tasks** are generated, including a global link back to the Master.

---

## ⌨️ Usage & Zed Integration

### 1. Daily Commands

| Command | Action |
| --- | --- |
| `make up` | Starts your project container in the background. |
| `make shell` | Opens a terminal inside the running container. |
| `make down` | Stops and removes the container. |
| `make fresh` | Resets the container (removes and restarts). |
| `make setup-zed` | Refreshes your editor UI from the current Makefile. |

### 2. The "Command Center" (Zed)

Press `Cmd+Shift+P` and type **"task: spawn"**. You will see your project tasks, plus:

* `🛠️ GLOBAL: Rebuild Master Environment`

Selecting this will trigger a rebuild of your global toolset from within your current project. Once finished, a simple `make up` (or "Docker Up" task) refreshes your container with the new tools.

---

## 🔐 Remote Access (Optional)

### SSH Into the Container

You can SSH into the container for remote access (e.g., from a laptop while traveling). This uses your **public key only** - your private key stays on your machine and is never copied into the container.

#### Local Development

For local development, set your SSH public key before starting the container:

```bash
# Add to your .env file (recommended)
echo "SSH_AUTHORIZED_KEYS=$(cat ~/.ssh/id_ed25519.pub)" >> .env

# Or export before docker-compose up
export SSH_AUTHORIZED_KEYS="$(cat ~/.ssh/id_ed25519.pub)"
docker-compose up -d
```

Then connect:
```bash
ssh -p $HOST_PORT_SSH user@localhost
```

#### Remote Access (On the Road)

To securely access your dev container from anywhere:

1. **Expose the SSH port** on your server/home machine (use your router's port forwarding or a service like Tailscale/Cloudflare Tunnel)

2. **Set your SSH public key** in the container's environment:
   ```bash
   # In your .env file on the server
   SSH_AUTHORIZED_KEYS="ssh-ed25519 AAAA... your-email@example.com"
   ```

3. **Connect from your laptop**:
   ```bash
   ssh -i ~/.ssh/id_ed25519 -p <exposed-port> user@your-server-ip
   ```

**Security notes:**
- Password authentication is completely disabled
- Root login via SSH is disabled
- Only users with authorized keys can connect

---

## 🔑 Advanced: Git Push From Inside Container (Optional)

If you want `git push` to work inside the container without exposing all your credentials, you can use **GitHub Deploy Keys**. These are SSH keys that only have access to a single repository.

### Setup Deploy Keys

1. **Generate a key for this repo only:**
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/deploy_myrepo -N "" -C "deploy key for myrepo"
   ```

2. **Add the public key to GitHub:** Go to your repo → Settings → Deploy Keys → Add deploy key. Check "Allow write access" if you want to push.

3. **Mount only this key** in `docker-compose.yml`:
   ```yaml
   volumes:
     - ~/.ssh/deploy_myrepo:/home/user/.ssh/id_ed25519:ro
     - ~/.ssh/deploy_myrepo.pub:/home/user/.ssh/id_ed25519.pub:ro
   ```

This gives the container push access to *one specific repo* while keeping your main SSH keys (with access to everything) safe on your host.

---

### Project-Specific Tools

If a project needs a unique tool that doesn't belong in the Master Image, just add it to that project's local `.devcontainer/Dockerfile`:

```dockerfile
FROM dev-env:latest
RUN apt-get install -y some-special-tool

```

---

## 🛠️ Troubleshooting

* **"Image dev-env:latest not found":** You haven't run `make build-master` in the `dev-init` folder yet.
* **"Permission Denied":** If files are owned by root, run `sudo chown -R $USER:$USER .` on your host.
* **Zed connection fails:** Run `make status` to ensure the SSH server inside the container is reachable.
