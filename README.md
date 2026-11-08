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
