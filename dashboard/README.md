# reco dashboard

A web layer on top of the `reco` CLI, modeled on two ideas from other recon
tools:

- **reNgine-style scan engines** — a scan is a YAML pipeline of named
  stages, each running one tool against a target.
- **Axiom-style distribution** — each stage is dispatched round-robin to a
  host from a pool you configure (SSH workers, or the dashboard's own
  machine), so a pipeline's stages run in parallel across your
  infrastructure instead of one process on one box.

It does **not** provision cloud VPS instances for you (unlike Axiom's
fleet command) — you add hosts you already control.

## Setup

```sh
cd reco
bash install_dashboard.sh          # gem deps: sinatra, puma, sequel, sqlite3, net-ssh
cd dashboard
ruby app.rb                        # http://127.0.0.1:4567, localhost-only by default
```

For a more production-style run: `puma -t 4:32 -b tcp://127.0.0.1:4567 config.ru`.

On first boot it seeds a `local` host (runs stages on the dashboard's own
machine, no SSH needed) and loads the engine definitions in `engines/*.yml`.

## Concepts

- **Targets** — a domain or IP you're scanning.
- **Hosts** — the worker pool. `local` runs on the dashboard's own machine;
  anything else is an SSH target (key-based auth is preferred; password auth
  is encrypted at rest with AES-256-GCM, key in `data/secret.key` — set
  `RECO_SECRET_KEY` yourself instead if you'd rather manage it). Each host
  needs `remote_path` pointing at a `reco` checkout on that machine (default
  `~/reco`) plus whichever tools its stages need already installed there.
- **Engines** — YAML pipelines. Edit them in the UI or drop files in
  `engines/*.yml` (loaded/upserted by name on boot). Stage fields:
  `name`, `tool` (see registry below), plus tool-specific options
  (`args`, `wordlist`, `threads`, `subtype`, ...).
- **Scans** — launching a scan against a target with an engine expands it
  into one task per stage, assigns each to a host round-robin, and runs
  them concurrently. The scan page streams live output and findings over
  SSE as they happen.
- **Findings** — normalized results (`subdomain`, `dns`, `port`,
  `directory`, `vulnerability`, `osint`, ...) parsed from each tool's
  stdout, browsable per-scan or across everything under **Findings**.

## Tool registry (`lib/tools.rb`)

| key | wraps | needs |
|---|---|---|
| `reco_subenum` | reco's own subdomain enum | nothing extra |
| `reco_dnsrecon` | reco's own DNS recon | nothing extra |
| `reco_portscan` | reco's own port scanner | nothing extra |
| `reco_vhostscan` | reco's own vhost bruteforce | nothing extra |
| `nmap` | nmap | `nmap` on the assigned host |
| `amass` | amass passive enum | `amass` |
| `masscan` | masscan | `masscan` (usually needs root) |
| `gobuster` | dir bruteforce | `gobuster` |
| `dirsearch` | dir bruteforce | `dirsearch` |
| `sqlmap` | SQLi probing | `sqlmap` |
| `spiderfoot` | OSINT sweep | `sf.py` on PATH |
| `burp` | Burp Suite scan via REST | a running Burp Suite **Professional/Enterprise** instance with its REST API enabled, plus `BURP_API_URL`/`BURP_API_KEY` env vars on the dashboard process. Community Edition has no scan API — there's nothing to fake here. |

A stage whose binary isn't installed on its assigned host is marked
**skipped** with a clear reason, not silently dropped or treated as a
scan failure.

## Security notes

- The dashboard can execute commands on every host in your pool. It binds
  to `127.0.0.1` by default (override with `RECO_DASHBOARD_BIND`). If you
  expose it beyond localhost, set `RECO_DASHBOARD_USER` /
  `RECO_DASHBOARD_PASS` to turn on HTTP basic auth — the app refuses
  nothing on your behalf, so this is on you to set.
- Prefer SSH key auth over password auth for hosts. Passwords are encrypted
  at rest, but a plaintext credential is still a plaintext credential in
  memory during use.
- `sqlmap`, `masscan`, and directory bruteforcing are intrusive. Only point
  engines that include them at hosts you're authorized to test.

## What's actually been verified vs. what needs your infrastructure

Built and tested in this environment: the full app boots, the DB schema,
scan dispatch, round-robin host assignment, local command execution, SSE
streaming (including a thread-leak fix — see `lib/executor.rb` /
`app.rb` history), and `reco`'s own modules (`reco_subenum`,
`reco_dnsrecon`, `reco_portscan`) running end-to-end against real domains
with findings parsed and stored correctly.

**Not verified here** (no such infrastructure in this sandbox): real SSH
distribution to a remote worker, and the nmap/amass/masscan/gobuster/
dirsearch/sqlmap/spiderfoot/Burp wrappers, since none of those binaries or
hosts exist in this environment. The command templates and output parsers
are code-complete and the "tool not found" / "host unreachable" paths are
tested, but the happy path for each external tool should be sanity-checked
against your actual hosts before you rely on it.
