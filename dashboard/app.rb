#!/usr/bin/env ruby
# reco dashboard: YAML scan engine pipelines distributed across an SSH
# host pool, with a live web UI.
$LOAD_PATH.unshift(File.expand_path('lib', __dir__))

require 'sinatra'
require 'sinatra/base'
require 'json'
require 'csv'
require 'yaml'

require 'rack/auth/basic'

require 'models'
require 'tools'
require 'executor'
require 'dispatcher'
require 'broadcaster'
require 'scheduler'
require_relative 'lib/crypto'
require_relative 'lib/credentials'
require_relative 'lib/osint_resources'

set :views, File.expand_path('views', __dir__)
set :public_folder, File.expand_path('public', __dir__)
set :bind, ENV.fetch('RECO_DASHBOARD_BIND', '127.0.0.1')
set :port, ENV.fetch('RECO_DASHBOARD_PORT', 4567)
set :server, 'puma'
set :show_exceptions, false
# Every open SSE connection occupies one Puma thread for its lifetime
# (Puma is threaded, not evented), so keep a generous pool.
set :server_settings, { Threads: '4:32' }

# Auth is always on: this dashboard can execute commands across every host
# in its pool, so there is no "run with no password" mode. Set
# RECO_DASHBOARD_USER/PASS yourself, or a random password is generated
# once and persisted to dashboard/data/admin_credentials.txt.
CREDENTIALS = Credentials.resolve
if CREDENTIALS[:source] == :generated
  warn "reco dashboard: generated admin credentials -> user=#{CREDENTIALS[:user]} pass=#{CREDENTIALS[:pass]}"
  warn "reco dashboard: saved to #{Credentials::CREDENTIALS_FILE} (override with RECO_DASHBOARD_USER/PASS)"
end
before do
  next if request.path_info == '/health' # unauthenticated so container/LB healthchecks work
  auth = Rack::Auth::Basic::Request.new(request.env)
  unless auth.provided? && auth.basic? && auth.credentials == [CREDENTIALS[:user], CREDENTIALS[:pass]]
    response['WWW-Authenticate'] = 'Basic realm="reco dashboard"'
    halt 401, 'Authorization required'
  end
end

get '/health' do
  content_type :json
  { status: 'ok' }.to_json
end

configure do
  # Seed a "local" execution host so a fresh install can run scans with no
  # SSH setup at all.
  if Host.where(auth_method: 'local').empty?
    Host.create(name: 'local', address: '127.0.0.1', auth_method: 'local', status: 'online', created_at: Time.now)
  end

  # Load bundled engine definitions from dashboard/engines/*.yml, upserting
  # by name so editing the files on disk and restarting picks up changes.
  Dir.glob(File.expand_path('engines/*.yml', __dir__)).each do |path|
    yaml = File.read(path)
    parsed = YAML.safe_load(yaml)
    next unless parsed && parsed['name']
    existing = Engine[name: parsed['name']]
    if existing
      existing.update(definition: yaml)
    else
      Engine.create(name: parsed['name'], definition: yaml, created_at: Time.now)
    end
  end

  Scheduler.start! unless ENV['RECO_DISABLE_SCHEDULER']
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text.to_s)
  end

  def tool_options
    Tools::TOOLS.keys
  end
end

# ---------------------------------------------------------------- overview
get '/' do
  @hosts = Host.all
  @targets = Target.all
  @engines = Engine.all
  @scans = Scan.order(Sequel.desc(:id)).limit(10).all
  erb :index
end

# --------------------------------------------------------------------- hosts
get '/hosts' do
  @hosts = Host.order(Sequel.desc(:id)).all
  erb :hosts
end

post '/hosts' do
  Host.create(
    name: params[:name],
    address: params[:address],
    port: (params[:port].to_i.zero? ? 22 : params[:port].to_i),
    ssh_user: (params[:ssh_user].to_s.empty? ? 'root' : params[:ssh_user]),
    auth_method: params[:auth_method],
    key_path: params[:key_path],
    encrypted_password: (params[:password].to_s.empty? ? nil : Crypto.encrypt(params[:password])),
    remote_path: (params[:remote_path].to_s.empty? ? '~/reco' : params[:remote_path]),
    status: 'unknown',
    created_at: Time.now
  )
  redirect '/hosts'
end

post '/hosts/:id/test' do
  host = Host[params[:id].to_i]
  halt 404 unless host
  result = Executor.test_connection(host)
  host.update(status: (result[:ok] ? 'online' : 'offline'), last_checked_at: Time.now)
  content_type :json
  result.to_json
end

post '/hosts/:id/delete' do
  host = Host[params[:id].to_i]
  halt 404 unless host
  halt 400, 'Cannot delete the local execution host' if host.local? && Host.where(auth_method: 'local').count <= 1
  halt 400, 'Cannot delete a host that has run scan tasks (their history references it)' if ScanTask.where(host_id: host.id).count.positive?
  host.destroy
  redirect '/hosts'
end

# ------------------------------------------------------------------- targets
get '/targets' do
  @targets = Target.order(Sequel.desc(:id)).all
  erb :targets
end

post '/targets' do
  Target.create(name: params[:name], notes: params[:notes], created_at: Time.now)
  redirect '/targets'
end

post '/targets/:id/delete' do
  target = Target[params[:id].to_i]
  halt 404 unless target
  halt 400, 'Cannot delete a target that has scans or schedules; delete those first' if Scan.where(target_id: target.id).count.positive? || ScheduledScan.where(target_id: target.id).count.positive?
  target.destroy
  redirect '/targets'
end

# ------------------------------------------------------------------- engines
get '/engines' do
  @engines = Engine.order(:name).all
  erb :engines
end

get '/engines/new' do
  @engine = nil
  erb :engine_form
end

get '/engines/:id/edit' do
  @engine = Engine[params[:id].to_i]
  halt 404 unless @engine
  erb :engine_form
end

post '/engines' do
  Engine.create(name: params[:name], definition: params[:definition], created_at: Time.now)
  redirect '/engines'
end

post '/engines/:id' do
  engine = Engine[params[:id].to_i]
  halt 404 unless engine
  engine.update(name: params[:name], definition: params[:definition])
  redirect '/engines'
end

post '/engines/:id/delete' do
  engine = Engine[params[:id].to_i]
  halt 404 unless engine
  halt 400, 'Cannot delete an engine that has scans or schedules; delete those first' if Scan.where(engine_id: engine.id).count.positive? || ScheduledScan.where(engine_id: engine.id).count.positive?
  engine.destroy
  redirect '/engines'
end

# --------------------------------------------------------------------- scans
get '/scans' do
  @scans = Scan.order(Sequel.desc(:id)).all
  @targets = Target.all
  @engines = Engine.all
  erb :scans
end

post '/scans' do
  target = Target[params[:target_id].to_i]
  engine = Engine[params[:engine_id].to_i]
  halt 400, 'Invalid target or engine' unless target && engine
  scan = Scan.create(target_id: target.id, engine_id: engine.id, status: 'queued', created_at: Time.now)
  Dispatcher.launch(scan)
  redirect "/scans/#{scan.id}"
end

get '/scans/:id' do
  @scan = Scan[params[:id].to_i]
  halt 404 unless @scan
  @tasks = ScanTask.where(scan_id: @scan.id).order(:id).all
  @findings = Finding.where(scan_id: @scan.id).order(Sequel.desc(:id)).all
  erb :scan_show
end

post '/scans/:id/cancel' do
  scan = Scan[params[:id].to_i]
  halt 404 unless scan
  scan.update(cancel_requested: true)
  Broadcaster.publish(scan.id, { type: 'scan_status', status: scan.status, message: 'Cancellation requested' })
  redirect "/scans/#{scan.id}"
end

get '/scans/:id/stream' do
  scan_id = params[:id].to_i
  halt 404 unless Scan[scan_id]
  content_type 'text/event-stream'
  headers['Cache-Control'] = 'no-cache'
  headers['X-Accel-Buffering'] = 'no'
  # Runs synchronously on this connection's own thread (Puma is threaded,
  # not evented, so a kept-open stream legitimately occupies one thread for
  # its lifetime). Do NOT spawn an extra Thread in here: writing to `out`
  # after this block returns is undefined and previously caused Puma to
  # spin up unbounded recovery threads.
  stream(:keep_open) do |out|
    q = Broadcaster.subscribe(scan_id)
    begin
      loop do
        event = q.pop(timeout: 15)
        if event.nil?
          out << ": heartbeat\n\n" # also surfaces a dead client via write failure
          next
        end
        out << "data: #{event.to_json}\n\n"
        break if event[:type] == 'scan_status' && %w[completed failed cancelled].include?(event[:status])
      end
    rescue StandardError, IOError
      # client disconnected or the connection errored out; fall through to cleanup
    ensure
      Broadcaster.unsubscribe(scan_id, q)
      out.close rescue nil
    end
  end
end

get '/scans/:id/findings.csv' do
  scan = Scan[params[:id].to_i]
  halt 404 unless scan
  content_type 'text/csv'
  attachment "scan-#{scan.id}-findings.csv"
  CSV.generate do |csv|
    csv << ['Kind', 'Value', 'Raw']
    Finding.where(scan_id: scan.id).each { |f| csv << [f.kind, f.value, f.raw] }
  end
end

# ------------------------------------------------------------------ findings
get '/findings' do
  @kind = params[:kind]
  ds = Finding.order(Sequel.desc(:id))
  ds = ds.where(kind: @kind) unless @kind.to_s.empty?
  @findings = ds.limit(500).all
  @kinds = Finding.distinct.select_map(:kind)
  erb :findings
end

# ----------------------------------------------------------------- schedules
get '/schedules' do
  @schedules = ScheduledScan.order(Sequel.desc(:id)).all
  @targets = Target.all
  @engines = Engine.all
  erb :schedules
end

post '/schedules' do
  target = Target[params[:target_id].to_i]
  engine = Engine[params[:engine_id].to_i]
  halt 400, 'Invalid target or engine' unless target && engine
  schedule_type = params[:schedule_type] == 'daily' ? 'daily' : 'interval'
  ScheduledScan.create(
    target_id: target.id, engine_id: engine.id, schedule_type: schedule_type,
    interval_minutes: (schedule_type == 'interval' ? params[:interval_minutes].to_i : nil),
    daily_at: (schedule_type == 'daily' ? params[:daily_at] : nil),
    active: true, created_at: Time.now
  )
  redirect '/schedules'
end

post '/schedules/:id/toggle' do
  s = ScheduledScan[params[:id].to_i]
  halt 404 unless s
  s.update(active: !s.active)
  redirect '/schedules'
end

post '/schedules/:id/delete' do
  s = ScheduledScan[params[:id].to_i]
  halt 404 unless s
  s.destroy
  redirect '/schedules'
end

# ------------------------------------------------------------------- osint
get '/osint' do
  @categories = OsintResources::CATEGORIES
  erb :osint
end
