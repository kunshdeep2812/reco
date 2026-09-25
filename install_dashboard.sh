#!/bin/bash
# Optional: installs the web dashboard's gem dependencies on top of the
# base reco install (run install.sh first). The dashboard itself lives in
# dashboard/ - see dashboard/README.md for setup, security notes, and how
# to add SSH worker hosts.

OKG='\033[92m'
OKO='\033[93m'
RESET='\e[0m'

echo -e "$OKO + -- --=[ Installing reco dashboard gem dependencies...$RESET"
gem install sinatra
gem install sinatra-contrib
gem install puma
gem install rackup
gem install sequel
gem install sqlite3
gem install net-ssh
echo -e "$OKG + -- --=[ Done! Run: cd dashboard && ruby app.rb $RESET"
echo -e "$OKG + -- --=[ Then open http://127.0.0.1:4567 (binds to localhost only by default) $RESET"
echo -e "$OKG + -- --=[ First boot prints a generated admin password - auth is always on. $RESET"
echo -e "$OKG + -- --=[ Or: docker compose up --build   /   cd dashboard && rake test $RESET"
