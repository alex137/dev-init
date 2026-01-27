
# 🛠️ Dev-Init: The Private Dev Platform

**Dev-Init** is a "Master-Base" development ecosystem. Instead of duplicating environment logic into every repository, it builds a single, high-performance **Master Image** that all your projects inherit from.

## 🏗️ The "Base Image" Philosophy

### Why do it this way?

* **One Source of Truth:** Update your toolset (Kotlin, Rust, Elixir, AI tools) in one place. All projects update automatically.
* **Instant Init:** Creating a new project takes seconds. No more 10-minute Docker builds for every new repo.
* **Disk Efficiency:** 50 projects sharing one 4GB image instead of 50 projects each having their own 4GB image (saving ~196GB of disk space).
* **Global Command Center:** Rebuild your entire platform from within any project using Zed tasks.

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

## 🔐 Security & Customization

### SSH Key-Based Authentication

The container uses **SSH key-based authentication only** (password login is disabled for security). This makes it safe to expose the SSH port for remote access when you're on the road.

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
