#!/usr/bin/env rackup
# Standard Rack entrypoint for production-style deployment, e.g.:
#   cd dashboard && puma -t 4:32 -p 4567 -e production config.ru
# (`ruby app.rb` also works directly for local/dev use.)
require_relative 'app'
run Sinatra::Application
