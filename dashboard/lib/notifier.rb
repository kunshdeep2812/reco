#!/usr/bin/env ruby
# Posts a scan-completion summary to Slack and/or Discord if their webhook
# URLs are configured. Does nothing if neither env var is set.
require 'net/http'
require 'uri'
require 'json'

module Notifier
  def self.scan_finished(scan)
    slack = ENV['SLACK_WEBHOOK_URL']
    discord = ENV['DISCORD_WEBHOOK_URL']
    return if slack.to_s.empty? && discord.to_s.empty?

    scan.refresh
    findings = Finding.where(scan_id: scan.id).count
    tasks = ScanTask.where(scan_id: scan.id)
    counts = tasks.group_and_count(:status).all.each_with_object({}) { |r, h| h[r[:status]] = r[:count] }

    text = build_text(scan, findings, counts)
    post_slack(slack, text) unless slack.to_s.empty?
    post_discord(discord, text) unless discord.to_s.empty?
  rescue StandardError
    # notifications are best-effort; a webhook failure must not affect the scan
  end

  def self.build_text(scan, findings_count, task_status_counts)
    status_line = task_status_counts.map { |k, v| "#{v} #{k}" }.join(', ')
    "reco scan ##{scan.id} #{scan.status}: target #{scan.target.name}, engine #{scan.engine.name}. " \
      "#{findings_count} findings. Stages: #{status_line}."
  end

  def self.post_slack(url, text)
    post_json(url, { text: text })
  end

  def self.post_discord(url, text)
    post_json(url, { content: text })
  end

  def self.post_json(url, payload)
    uri = URI.parse(url)
    return unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = 5
    http.read_timeout = 5
    req = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
    req.body = payload.to_json
    http.request(req)
  rescue StandardError
    nil
  end
end
