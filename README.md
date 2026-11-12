# Homelab

Docker Compose stacks for a homelab, deployed from GitLab CI. German and English documentation is built from `src/docs` and published with GitLab Pages.

## Layout

| Path                        | Purpose                                                       |
| --------------------------- | ------------------------------------------------------------- |
| `src/docker`                | One Compose file per service.                                 |
| `src/.config`               | Configuration rendered onto the host.                         |
| `src/cli`                   | Secrets, generation, SSH, and Compose deploy.                 |
| `src/docs`                  | Documentation site. Markdown lives in `src/docs/src/content`. |
| `.gitlab/homelab.yml`       | Deploy pipeline.                                              |
| `.gitlab/documentation.yml` | Pages pipeline.                                               |

## Documentation

```bash
cd src/docs
npm ci
npm run build
```

`npm run build` compiles TypeScript and the Markdown into `src/docs/public`. German is the default language. The site stores the language and the light or dark theme in the browser.

## Deploy

A push to the default branch deploys changed Compose files and, when `src/docs` changes, the documentation. Secrets stay in Bitwarden Secrets Manager and are not part of this repository.

## Local Make commands

Run `make` or `make help` at the repository root to list the available commands. `make check` validates shell syntax and the paths configuration; `make paths` prints the directories resolved from [`src/.config/bash/paths.json`](src/.config/bash/paths.json).

### Zsh and paths

`make zsh-install` syncs the single Zsh startup file from `src/.config/zsh` to `~/.zshrc`, the Powerlevel10k config to `~/.config/.p10k.zsh`, and the path resolver plus `paths.json` to `~/.config/homelab/`. The repository root is resolved from the `SETUP_ROOT` entry in `paths.json`; update that entry if you move the checkout. Restart Zsh after syncing. `make zsh-oh-my-zsh` optionally installs Oh My Zsh after confirmation.

### CLI and deployment

| Command | Purpose |
| --- | --- |
| `make bitwarden` / `make bitwarden-get SECRET_KEY=EMAIL` | Fetch secrets or read one generated value. |
| `make generate` | Render and deploy generated configuration. |
| `make ssh` | Connect and show the remote deployment directory. |
| `make ssh-run COMMAND="docker ps"` | Run a command through `src/cli/ssh.sh ssh_run`. |
| `make compose-list` / `make compose-upload` | List selected stacks or upload without deploying; uploads and remote Compose commands are dispatched through `src/cli/ssh.sh`. |
| `make compose COMPOSE_STACKS="traefik dashy"` | Deploy selected stack(s) over SSH; without the variable it deploys changed stacks. |
| `make docker DOCKER_STACK=dashboard DOCKER_ARGS="up -d"` | Run a Docker Compose command for one stack; project name, env file, and `src/docker/<stack>.yml` are resolved automatically. |
| `make deploy` | Run the full CLI deployment sequence. |
| `make ssh-key-setup` | Create/show the local key **and reset `~/.ssh/known_hosts`**. |
| `make pull` | Run `pull.sh`; when the worktree is clean it can commit and push changes. |

### Settings and security

- `make settings-brew BREW_ARGS="--list"` lists Homebrew packages. Use `BREW_ARGS=all`, `formulae`, or `casks` to install; selected formulae/casks can be supplied after those modes, for example `make settings-brew BREW_ARGS="formulae git gh"`.
- `make settings-git` configures the global Git identity using the generated Bitwarden secrets.
- `make settings-tailscale` enables IP forwarding and advertises the configured Tailscale routes.
- `make settings-pull-schedule` reports the LaunchAgent status. Set `ACTION=install`, `remove`, or `run` to manage or run it.
- `make security` runs all security checks. Set `SECURITY_COMMAND=host`, `host-harden`, `github`, `virus`, or `gitleaks` to run one check. For virus and gitleaks scans, `IMAC_REPO_DIR` from Bitwarden sets the repository scan path; you can override it with `IMAC_REPO_DIR=/path/to/scan`. `host-harden` changes macOS firewall settings after confirmation.

Commands that install packages, modify system settings, reset SSH host keys, deploy services, or commit/push changes can have lasting effects. Review their output and prompts before confirming.
