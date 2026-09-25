# This couldn't be built end-to-end in the environment that authored it:
# its sandbox blocks container egress to deb.debian.org (policy denial, not
# a transient error), so the apt-get layer was never exercised there. The
# `FROM` pull and the full `gem install` list (this Dockerfile's other two
# network-touching steps) were each validated directly in that sandbox
# against a real Docker daemon. Build this yourself once before relying on
# it; see dashboard/README.md for the exact breakdown of what's confirmed.

FROM ruby:3.3-slim

# Base OS deps for native gem extensions (sqlite3, nokogiri deps pulled in
# transitively, etc.) plus a handful of recon tools that are plain apt
# packages. The Go/Python-based tools in dashboard/lib/tools.rb (amass,
# subfinder, httpx, naabu, nuclei, ffuf, gobuster, sqlmap, spiderfoot,
# theHarvester, wafw00f, dalfox, subzy, waybackurls, dirsearch) are
# intentionally NOT bundled here - they'd roughly triple the image size and
# need per-tool toolchains (Go, pip, ...) this Dockerfile doesn't set up.
# Install what you need on top of this image, or run those stages on an
# SSH worker host that has them instead of the dashboard container itself.
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      libssl-dev \
      libsqlite3-dev \
      sqlite3 \
      nmap \
      masscan \
      whois \
      git \
      curl \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

# Core reco CLI gems (requirements.txt) + dashboard gems (dashboard/requirements.txt)
RUN gem install \
      ipaddr ipaddress httparty colorize csv timeout ruby-progressbar \
      faye-websocket eventmachine json terminal-table fileutils \
      sinatra sinatra-contrib puma rackup sequel sqlite3 net-ssh

ENV RECO_DASHBOARD_BIND=0.0.0.0
ENV RECO_DASHBOARD_PORT=4567
EXPOSE 4567

# selenium-webdriver (used by reco.rb's redirect-scr screenshot module) needs
# a system chromedriver this image doesn't install; that one CLI script isn't
# needed for the dashboard itself, so it's left out rather than bloating the
# image on a guess of what version/arch you'd want.

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD curl -f http://127.0.0.1:4567/health || exit 1

WORKDIR /app/dashboard
CMD ["ruby", "app.rb"]
