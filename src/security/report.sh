#!/usr/bin/env bash

[[ -n "${SEC_REPORT_LOADED:-}" ]] && return 0
SEC_REPORT_LOADED=1

_sec_css() {
  cat <<'CSS'
  :root {
    --bg: #1c1c1c; --fg: #e8e8e8; --muted: #9a9a9a; --line: #333;
    --ok: #3d9a6a; --warn: #c47a2c; --info: #4a8fc7; --danger: #c45c5c;
    --card: #242424;
  }
  * { box-sizing: border-box; }
  body {
    margin: 0; background: var(--bg); color: var(--fg);
    font: 15px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  }
  main { max-width: 980px; margin: 0 auto; padding: 32px 24px 64px; }
  h1 { font-size: 24px; font-weight: 600; margin: 0 0 8px; }
  h2 { font-size: 18px; font-weight: 600; margin: 36px 0 12px; }
  .sub { color: var(--muted); margin: 0 0 20px; }
  .callout {
    background: var(--card); border: 1px solid var(--line);
    border-left: 3px solid var(--accent, var(--ok)); padding: 14px 16px; margin: 0 0 24px;
  }
  .stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 8px; }
  .stat { background: var(--card); border: 1px solid var(--line); padding: 14px 16px; }
  .stat b { display: block; font-size: 22px; font-weight: 600; }
  .stat span { color: var(--muted); font-size: 12px; }
  .ok { color: var(--ok); } .warn { color: var(--warn); }
  .info { color: var(--info); } .danger { color: var(--danger); }
  table { width: 100%; border-collapse: collapse; font-size: 14px; }
  th, td { text-align: left; vertical-align: top; padding: 10px 12px;
           border-bottom: 1px solid var(--line); word-break: break-word; }
  th { color: var(--muted); font-weight: 500; }
  tr:nth-child(even) td { background: #202020; }
  .dot { display: inline-block; width: 7px; height: 7px; border-radius: 50%;
          margin-right: 8px; vertical-align: middle; }
  .dot.ok { background: var(--ok); } .dot.warn { background: var(--warn); }
  .dot.info { background: var(--info); } .dot.danger { background: var(--danger); }
  .pills { display: flex; gap: 8px; align-items: center; margin-top: 28px;
            padding-top: 16px; border-top: 1px solid var(--line); flex-wrap: wrap; }
  .pill { border: 1px solid var(--line); padding: 4px 10px; font-size: 12px; color: var(--muted); }
  @media (max-width: 900px) { .stats { grid-template-columns: 1fr 1fr; } }
CSS
}

sec_write_kind() {
  local kind="$1"
  local out css prefix proxy
  case "$kind" in
    host) out="$HTML_HOST" ;;
    github) out="$HTML_GITHUB" ;;
    virus) out="$HTML_VIRUS" ;;
    gitleaks) out="$HTML_GITLEAKS" ;;
    *) echo "unknown html kind: $kind" >&2; return 1 ;;
  esac
  css="$(_sec_css)"
  prefix="$(env_val HOMELAB_IP_PREFIX)"
  proxy="$(env_val HOMELAB_PROXY_HOST)"
  proxy="${proxy:-2}"
  python3 - "$kind" "$out" "$css" \
    "$HOST_CHECKS" "$GITHUB_CHECKS" "$VIRUS_CHECKS" \
    "$HITS" "$AGENTS" "$NMAP_TSV" "$DOCKER_TSV" "$GITHUB_TSV" "$TARGETS_FILE" \
    "$prefix" "$proxy" "$GITLEAKS_CHECKS" "$GITLEAKS_TSV" <<'PY'
import html
from datetime import datetime
from pathlib import Path
import sys

kind, out_s, css = sys.argv[1], sys.argv[2], sys.argv[3]
host_c, gh_c, vir_c = map(Path, sys.argv[4:7])
hits_p, agents_p, nmap_p, docker_p, github_p, targets_p = map(Path, sys.argv[7:13])
prefix = (sys.argv[13] if len(sys.argv) > 13 else "").strip()
proxy = (sys.argv[14] if len(sys.argv) > 14 else "2").strip() or "2"
gl_c = Path(sys.argv[15]) if len(sys.argv) > 15 else Path("/dev/null")
gl_p = Path(sys.argv[16]) if len(sys.argv) > 16 else Path("/dev/null")
cidr = f"{prefix}.0/24" if prefix else "(HOMELAB_IP_PREFIX missing)"
gw = f"{prefix}.1" if prefix else "router (.1)"
e = html.escape
now = datetime.now().astimezone().strftime("%Y-%m-%d %H:%M:%S %Z")

def tsv(path, n=3):
    if not path.is_file() or path.stat().st_size == 0:
        return []
    rows = []
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        parts = line.split("\t")
        if not parts or not parts[0]:
            continue
        while len(parts) < n:
            parts.append("")
        rows.append(parts[:n])
    return rows

def tr_checks(rows):
    if not rows:
        return "<tr><td>—</td><td>No checks</td></tr>"
    return "".join(
        f'<tr><td><span class="dot {e(t)}"></span>{e(title)}</td><td>{e(detail)}</td></tr>'
        for t, title, detail in rows
    )

def page(title, accent, callout, stats, body):
    stats_html = "".join(
        f'<div class="stat"><b class="{e(tone)}">{e(str(val))}</b><span>{e(label)}</span></div>'
        for val, label, tone in stats
    )
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>{e(title)}</title>
<style>
{css}
  .callout {{ --accent: var(--{accent}); }}
</style>
</head>
<body>
<main>
  <h1>{e(title)}</h1>
  <p class="sub">Generated {e(now)}. No secret values.</p>
  <div class="callout">{e(callout)}</div>
  <div class="stats">{stats_html}</div>
  {body}
  <div class="pills">
    <span class="pill">{e(kind)}.html</span>
    <span class="sub" style="margin:0">setup → Security — virus — gitleaks</span>
  </div>
</main>
</body>
</html>
"""

out = Path(out_s)
out.parent.mkdir(parents=True, exist_ok=True)

if kind == "host":
    checks = tsv(host_c)
    nmap = tsv(nmap_p, 2)
    docker = tsv(docker_p, 3)
    fw_off = any(r[0] == "warn" and "firewall" in r[1].lower() for r in checks)
    wild = any("0.0.0.0" in (r[1] + r[2]) for r in docker + checks)
    nmap_html = []
    for row in nmap:
        ip, ports = row[0], row[1]
        nmap_html.append(f'<tr><td><span class="dot warn"></span>{e(ip)}</td><td>{e(ports)}</td></tr>')
    if not nmap_html:
        nmap_html.append("<tr><td>—</td><td>No nmap data</td></tr>")
    docker_html = []
    for row in docker:
        name, cport, bind = row[0], row[1], row[2]
        t = "danger" if bind.startswith(("0.0.0.0:", "*:", "[::]:")) else "ok"
        docker_html.append(
            f'<tr><td><span class="dot {t}"></span>{e(name)}</td><td>{e(cport)}</td><td>{e(bind)}</td></tr>'
        )
    if not docker_html:
        docker_html.append("<tr><td>—</td><td>—</td><td>No published ports</td></tr>")
    accent = "danger" if wild else "ok"
    callout = "LAN prefix from Bitwarden is RFC1918. Docker binds and nmap are on this page only."
    body = f"""
  <h2>Why not on the internet</h2>
  <table>
    <thead><tr><th>Check</th><th>Result</th></tr></thead>
    <tbody>
      <tr><td><span class="dot ok"></span>Address</td><td><code>{e(cidr)}</code> from HOMELAB_IP_PREFIX</td></tr>
      <tr><td><span class="dot ok"></span>NAT</td><td>Gateway <code>{e(gw)}</code> (router)</td></tr>
      <tr><td><span class="dot ok"></span>Traefik</td><td>LAN allowlist, proxy host .{e(proxy)}</td></tr>
    </tbody>
  </table>
  <h2>nmap / open ports</h2>
  <table><thead><tr><th>Host</th><th>Open</th></tr></thead><tbody>{"".join(nmap_html)}</tbody></table>
  <h2>Docker publishes</h2>
  <table><thead><tr><th>Container</th><th>Port</th><th>Bind</th></tr></thead><tbody>{"".join(docker_html)}</tbody></table>
  <h2>Checks</h2>
  <table><thead><tr><th>Check</th><th>Result</th></tr></thead><tbody>{tr_checks(checks)}</tbody></table>
"""
    html_out = page(
        "Host / LAN",
        accent,
        callout,
        [
            ("Off" if fw_off else "On", "macOS firewall", "danger" if fw_off else "ok"),
            (cidr, "LAN prefix", "info"),
            ("Yes" if wild else "No", "0.0.0.0 publish", "danger" if wild else "ok"),
            ("Flat", "LAN (lateral)", "warn"),
        ],
        body,
    )

elif kind == "github":
    checks = tsv(gh_c)
    repos = tsv(github_p, 4)
    repo_html = []
    for row in repos:
        full, priv, vis, url = row[0], row[1], row[2], row[3]
        t = "ok" if priv == "true" else "info"
        label = "private" if priv == "true" else "public"
        repo_html.append(
            f'<tr><td><span class="dot {t}"></span>{e(full)}</td><td>{e(label)}</td><td>{e(url)}</td></tr>'
        )
    if not repo_html:
        repo_html.append("<tr><td>—</td><td>—</td><td>No GitHub data</td></tr>")
    priv_n = sum(1 for r in repos if r[1] == "true")
    pub_n = sum(1 for r in repos if r[1] != "true")
    leaks = sum(1 for r in checks if r[0] == "danger")
    accent = "danger" if leaks else "ok"
    callout = (
        f"{leaks} GitHub alert(s). Rotate secrets; values are not printed."
        if leaks
        else "Private repos are not reachable without login. No open secret-scanning alerts listed."
    )
    body = f"""
  <h2>Repositories</h2>
  <table><thead><tr><th>Repo</th><th>Visibility</th><th>URL</th></tr></thead><tbody>{"".join(repo_html)}</tbody></table>
  <h2>Checks</h2>
  <table><thead><tr><th>Check</th><th>Result</th></tr></thead><tbody>{tr_checks(checks)}</tbody></table>
"""
    html_out = page(
        "GitHub",
        accent,
        callout,
        [
            (str(len(repos)), "Owned repos", "info"),
            (str(priv_n), "Private", "ok"),
            (str(pub_n), "Public", "info"),
            (str(leaks), "Secret alerts", "danger" if leaks else "ok"),
        ],
        body,
    )

elif kind == "virus":
    checks = tsv(vir_c)
    hits = tsv(hits_p, 3)
    agents = []
    if agents_p.is_file():
        agents = [ln for ln in agents_p.read_text(encoding="utf-8", errors="replace").splitlines() if ln.strip()]
    targets = targets_p.read_text(encoding="utf-8", errors="replace").strip() if targets_p.is_file() else ""
    n_hits = len(hits)
    love = sum(1 for r in hits if r[0] == "LoveLetter")
    trojan = sum(1 for r in hits if r[0] == "Trojan")
    worm = sum(1 for r in hits if r[0] == "Worm")
    virus = sum(1 for r in hits if r[0] == "Virus")
    hit_html = []
    for kind_h, sig, path in hits:
        hit_html.append(
            f'<tr><td><span class="dot danger"></span>{e(kind_h)}</td><td>{e(sig)}</td><td><code>{e(path)}</code></td></tr>'
        )
    if not hit_html:
        hit_html.append('<tr><td><span class="dot ok"></span>None</td><td>—</td><td>Clean</td></tr>')
    agent_html = "".join(f"<tr><td><code>{e(p)}</code></td></tr>" for p in agents) or "<tr><td>No user LaunchAgents</td></tr>"
    accent = "danger" if n_hits else "ok"
    callout = (
        f"{n_hits} detection(s). Do not open those files. Quarantine or delete, then re-run setup → Security → Virus."
        if n_hits
        else "No virus, worm, Trojan, LoveLetter, or PUA detections in scanned paths."
    )
    body = f"""
  <p class="sub">Paths: {e(targets or "none")}</p>
  <h2>Detections</h2>
  <table><thead><tr><th>Type</th><th>Signature</th><th>Path</th></tr></thead><tbody>{"".join(hit_html)}</tbody></table>
  <h2>User LaunchAgents</h2>
  <table><thead><tr><th>Path</th></tr></thead><tbody>{agent_html}</tbody></table>
  <h2>Checks</h2>
  <table><thead><tr><th>Check</th><th>Result</th></tr></thead><tbody>{tr_checks(checks)}</tbody></table>
"""
    html_out = page(
        "Virus scan",
        accent,
        callout,
        [
            (str(n_hits), "Detections", "danger" if n_hits else "ok"),
            (str(love), "LoveLetter", "info"),
            (str(trojan), "Trojan", "info"),
            (f"{worm}/{virus}", "Worm / virus", "info"),
        ],
        body,
    )

elif kind == "gitleaks":
    checks = tsv(gl_c)
    leaks = tsv(gl_p, 4)
    leak_html = []
    for repo, path, rule, line in leaks:
        leak_html.append(
            f'<tr><td><span class="dot danger"></span>{e(repo)}</td>'
            f"<td><code>{e(path)}</code></td><td>{e(rule)}</td><td>{e(line)}</td></tr>"
        )
    if not leak_html:
        leak_html.append(
            '<tr><td><span class="dot ok"></span>—</td><td>—</td><td>clean</td><td>—</td></tr>'
        )
    n_leaks = len(leaks)
    repos = {row[0] for row in leaks}
    dirty = sum(1 for r in checks if r[0] == "danger")
    accent = "danger" if n_leaks else "ok"
    callout = (
        f"{n_leaks} finding(s) in {len(repos)} repo(s). Secret values are not printed. Rotate those secrets."
        if n_leaks
        else "No gitleaks findings. Report lists file, rule, and line only — never secret values."
    )
    body = f"""
  <h2>Findings</h2>
  <table>
    <thead><tr><th>Repo</th><th>File</th><th>Rule</th><th>Line</th></tr></thead>
    <tbody>{"".join(leak_html)}</tbody>
  </table>
  <h2>Checks</h2>
  <table><thead><tr><th>Check</th><th>Result</th></tr></thead><tbody>{tr_checks(checks)}</tbody></table>
"""
    html_out = page(
        "gitleaks",
        accent,
        callout,
        [
            (str(n_leaks), "Findings", "danger" if n_leaks else "ok"),
            (str(dirty), "Repos with hits", "danger" if dirty else "ok"),
            (str(len(checks)), "Repos scanned", "info"),
            ("redacted", "Secret values", "ok"),
        ],
        body,
    )

else:
    raise SystemExit(f"unknown html kind: {kind}")

out.write_text(html_out, encoding="utf-8")
print(out)
PY
  sec_log "HTML: $out"
}

sec_write_reports() {
  local opened=0
  if [[ "${SEC_RAN_HOST:-0}" == 1 ]]; then
    sec_write_kind host
    command -v open >/dev/null && open "$HTML_HOST"
    opened=1
  fi
  if [[ "${SEC_RAN_GITHUB:-0}" == 1 ]]; then
    sec_write_kind github
    command -v open >/dev/null && open "$HTML_GITHUB"
    opened=1
  fi
  if [[ "${SEC_RAN_VIRUS:-0}" == 1 ]]; then
    sec_write_kind virus
    command -v open >/dev/null && open "$HTML_VIRUS"
    opened=1
  fi
  if [[ "${SEC_RAN_GITLEAKS:-0}" == 1 ]]; then
    sec_write_kind gitleaks
    command -v open >/dev/null && open "$HTML_GITLEAKS"
    opened=1
  fi
  if [[ "$opened" -eq 0 ]]; then
    sec_log "No HTML written (nothing ran)."
  fi
}
