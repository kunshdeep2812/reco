# reco dashboard

A web layer on top of the `reco` CLI:

- **Scan engines** — a scan is a YAML pipeline of named stages, each
  running one tool against a target. A stage can chain off an earlier
  stage's findings (e.g. probe every subdomain a previous stage found)
  instead of only ever scanning the top-level target.
- **Distributed execution** — each stage is dispatched to whichever host
  is currently least busy, from a pool you configure (SSH workers, or the
  dashboard's own machine), so a pipeline's stages run in parallel across
  your infrastructure instead of one process on one box. Per-stage
  timeouts and scan cancellation both actually kill the running process
  tree (or the remote process, over SSH), not just stop watching it.
- **Scheduling & notifications** — recurring scans on an interval or a
  daily time, with an optional Slack/Discord ping when a scan finishes.

It does **not** provision cloud VPS instances for you — you add hosts you
already control.

## Setup

```sh
cd reco
bash install_dashboard.sh          # gem deps: sinatra, puma, sequel, sqlite3, net-ssh
cd dashboard
ruby app.rb                        # http://127.0.0.1:4567, localhost-only by default
```

The first boot prints a generated admin password (also saved to
`dashboard/data/admin_credentials.txt`) — auth is always on, there is no
unauthenticated mode. Set `RECO_DASHBOARD_USER`/`RECO_DASHBOARD_PASS`
yourself to pin it instead.

For a more production-style run: `puma -t 4:32 -b tcp://127.0.0.1:4567 config.ru`.
Or via Docker: `docker compose up --build` (see **Docker** below).

On first boot it also seeds a `local` host (runs stages on the dashboard's
own machine, no SSH needed) and loads the engine definitions in
`engines/*.yml`.

## Concepts

- **Targets** — a domain or IP you're scanning.
- **Hosts** — the worker pool. `local` runs on the dashboard's own machine;
  anything else is an SSH target (key-based auth is preferred; password auth
  is encrypted at rest with AES-256-GCM, key in `data/secret.key` — set
  `RECO_SECRET_KEY` yourself instead if you'd rather manage it). Each host
  needs `remote_path` pointing at a `reco` checkout on that machine (default
  `~/reco`) plus whichever tools its stages need already installed there.
  Stages are handed to whichever host currently has the fewest active
  tasks, not blind round-robin.
- **Engines** — YAML pipelines. Edit them in the UI or drop files in
  `engines/*.yml` (loaded/upserted by name on boot). Stage fields:
  - `name`, `tool` (see registry below)
  - tool-specific options: `args`, `wordlist`, `threads`, `subtype`, ...
  - `timeout`: seconds before the stage is killed and marked `timeout`
  - `chain_from`: an earlier stage's `name` — instead of running once
    against the scan's target, this stage runs once per distinct finding
    that stage produced
  - `chain_kind`: which finding kind to chain over (default `subdomain`)
  - `chain_limit`: cap on how many chained targets to fan out to (default 25)

  Example:
  ```yaml
  name: chained-example
  stages:
    - name: subdomain_enum
      tool: reco_subenum
      subtype: full
    - name: probe_live_hosts
      tool: httpx
      chain_from: subdomain_enum
      chain_kind: subdomain
      chain_limit: 25
      timeout: 120
  ```
- **Scans** — launching a scan against a target with an engine expands it
  into one task per stage (plus one per chained fan-out target), assigns
  each to the least-busy host, and runs them concurrently. The scan page
  streams live output and findings over SSE as they happen, and can cancel
  a running scan (kills in-flight processes, local or remote).
- **Schedules** — a target + engine pair that launches automatically, every
  N minutes or daily at a given time. Checked every 30 seconds by a
  background thread in the dashboard process.
- **Findings** — normalized results (`subdomain`, `dns`, `port`,
  `directory`, `vulnerability`, `osint`, `http`, `url`, `whois`,
  `takeover`, `waf`, ...) parsed from each tool's stdout, browsable
  per-scan or across everything under **Findings**.
- **OSINT resources** — a static, curated bookmarks page of well-known
  public OSINT tools (Shodan, crt.sh, Have I Been Pwned, ...) for the parts
  of recon that aren't a single command to automate. Nothing on it runs
  from the dashboard.

## Tool registry (`lib/tools.rb`)

| key | wraps | needs |
|---|---|---|
| `reco_subenum` | reco's own subdomain enum | nothing extra |
| `reco_dnsrecon` | reco's own DNS recon | nothing extra |
| `reco_portscan` | reco's own port scanner | nothing extra |
| `reco_vhostscan` | reco's own vhost bruteforce | nothing extra |
| `nmap` | port/service scan | `nmap` |
| `amass` | passive subdomain enum | `amass` |
| `masscan` | fast port scan | `masscan` (usually needs root) |
| `gobuster` | dir bruteforce | `gobuster` |
| `dirsearch` | dir bruteforce | `dirsearch` |
| `sqlmap` | SQLi probing | `sqlmap` |
| `spiderfoot` | OSINT sweep | `sf.py` on PATH |
| `subfinder` | passive subdomain enum | `subfinder` |
| `httpx` | live host probe (status/title) | `httpx` |
| `naabu` | fast port scan | `naabu` |
| `nuclei` | vulnerability templates | `nuclei` |
| `ffuf` | web fuzzer | `ffuf` |
| `waybackurls` | historical URL discovery | `waybackurls` |
| `dalfox` | XSS scanning | `dalfox` |
| `theharvester` | OSINT (emails, hosts) | `theHarvester` |
| `whois` | registration lookup | `whois` |
| `subzy` | subdomain takeover check | `subzy` |
| `wafw00f` | WAF fingerprinting | `wafw00f` |
| `burp` | Burp Suite scan via REST | a running Burp Suite **Professional/Enterprise** instance with its REST API enabled, plus `BURP_API_URL`/`BURP_API_KEY` env vars on the dashboard process. Community Edition has no scan API — there's nothing to fake here. |

A stage whose binary isn't installed on its assigned host is marked
**skipped** with a clear reason, not silently dropped or treated as a
scan failure.

## Notifications

Set `SLACK_WEBHOOK_URL` and/or `DISCORD_WEBHOOK_URL` and every scan posts a
one-line summary (target, engine, status, finding count) when it finishes.
Neither is required; nothing is sent if both are unset, and a webhook
failure never affects the scan itself.

## Docker

```sh
docker compose up --build
```

Persists `dashboard/data` (DB, encryption key, admin credentials) in a
named volume. Set env vars in `docker-compose.yml` for credentials,
webhooks, or Burp. The bundled `Dockerfile` installs the dashboard's Ruby
gems plus `nmap`/`masscan`/`whois` via apt; the Go/Python tools in the
registry above (subfinder, httpx, naabu, nuclei, ffuf, gobuster, sqlmap,
spiderfoot, theHarvester, wafw00f, dalfox, subzy, waybackurls, dirsearch)
are **not** bundled — install them on top of this image, or run those
stages on an SSH worker host that already has them.

## Security notes

- Auth is always on (see **Setup**) — there is no unauthenticated mode,
  since this dashboard can execute commands across every host in its pool.
  It binds to `127.0.0.1` by default; override with `RECO_DASHBOARD_BIND`
  if you need it reachable elsewhere.
- Prefer SSH key auth over password auth for hosts. Passwords are encrypted
  at rest, but a plaintext credential is still a plaintext credential in
  memory during use.
- `sqlmap`, `masscan`, `nuclei`, `dalfox`, and directory bruteforcing are
  intrusive. Only point engines that include them at hosts and targets
  you're authorized to test.
- Deleting a host/target/engine that a scan or schedule still references
  is refused with a clear error rather than corrupting history.

## Automated tests

```sh
cd dashboard
rake test   # minitest; runs against a throwaway sqlite file, never dashboard/data/
```

Covers: `Tools` command building and output parsing for every registered
tool, `Crypto` roundtrip, `Executor` (normal run, timeout kill, cancellation
— against real subprocesses), `HostLoad` least-busy selection, `Scheduler`
due/interval/daily logic, and `Dispatcher` (chaining fan-out, cancellation,
per-stage timeout, unknown-tool handling) via a stubbed tool registry so
these don't depend on external binaries or the network.

## What's actually been verified vs. what needs your infrastructure

Built and tested end-to-end in the environment that authored this,
against a real running app (not just unit tests): scan dispatch including
stage chaining and least-busy host assignment, per-stage timeouts and
mid-scan cancellation (confirmed no orphaned processes), the scheduler
firing a real scan through the actual HTTP API, Slack notification
delivery to a mock webhook, enforced auth (401/200 checked directly), and
`reco`'s own modules (`reco_subenum`, `reco_dnsrecon`, `reco_portscan`)
running for real against live domains with findings parsed and stored
correctly. The Docker build was validated in two pieces (base image pull,
then the full gem install list against a real daemon) because this
environment's own network policy blocks apt access to deb.debian.org — see
the note at the top of the `Dockerfile`.

**Not verified here** (no such infrastructure in this sandbox): real SSH
distribution to a remote worker, and the 19 external-tool wrappers (nmap,
amass, masscan, gobuster, dirsearch, sqlmap, spiderfoot, subfinder, httpx,
naabu, nuclei, ffuf, waybackurls, dalfox, theHarvester, whois, subzy,
wafw00f, Burp), since none of those binaries or hosts exist in this
environment. Their command templates and output parsers are exercised by
the test suite against sample output, and the "tool not found" / "host
unreachable" paths are tested end-to-end, but the happy path for each
external tool against its real binary should be sanity-checked against
your actual hosts before you rely on it.
