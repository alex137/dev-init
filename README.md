
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
| `make up` | Starts your project using the Master Image. |
| `make test` | **Auto-detects** language (Rust/Elixir/Kotlin) and runs tests. |
| `make setup-zed` | Refreshes your editor UI from the current Makefile. |

### 2. The "Command Center" (Zed)

Press `Cmd+Shift+P` and type **"task: spawn"**. You will see your project tasks, plus:

* `🛠️ GLOBAL: Rebuild Master Environment`

Selecting this will trigger a rebuild of your global toolset from within your current project. Once finished, a simple `make up` (or "Docker Up" task) refreshes your container with the new tools.

---

## 🔐 Security & Customization

### SSH Keys

To login without a password, your `dev-init` setup is pre-configured to look for your public key. Ensure your local `~/.ssh/id_rsa.pub` exists; it will be mounted automatically into the container by `docker-compose`.

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


## TODO
gitignore in the other eports
ignore .env and projects.reg here
tasks.json
