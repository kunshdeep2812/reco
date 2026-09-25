#!/usr/bin/env ruby
# Lightweight HTTP technology / CMS fingerprinting used by portscan and vhostfind.
$VERBOSE = nil

module Fingerprint
  CMS_SIGNATURES = {
    "WordPress" => /wp-content|wp-includes|wp-json/i,
    "Joomla"    => /\/media\/jui\/|joomla/i,
    "Drupal"    => /sites\/default\/files|drupal\.js|X-Drupal-Cache/i,
    "Magento"   => /Mage\.Cookies|magento/i,
    "Shopify"   => /cdn\.shopify\.com|X-Shopify-Stage/i,
    "Laravel"   => /laravel_session/i,
    "Django"    => /csrftoken/i,
    "ASP.NET"   => /X-AspNet-Version|__VIEWSTATE|ASP\.NET_SessionId/i,
    "Nginx"     => /nginx/i,
    "Apache"    => /Apache/i,
    "IIS"       => /Microsoft-IIS/i,
    "Jenkins"   => /X-Jenkins/i,
    "phpMyAdmin"=> /pma_username|phpMyAdmin/i,
    "Tomcat"    => /Apache Tomcat/i
  }

  def self.identify(response)
    return "Unknown" if response.nil?
    headers = (response.headers.to_h rescue {})
    header_blob = headers.to_a.flatten.join(" ")
    body = (response.body.to_s rescue "")[0, 20000]

    hits = []

    server = headers["server"] || headers["Server"]
    hits << "Server: #{server}" if server
    xpb = headers["x-powered-by"] || headers["X-Powered-By"]
    hits << "X-Powered-By: #{xpb}" if xpb

    CMS_SIGNATURES.each do |name, regex|
      next if hits.any? { |h| h.include?(name) }
      hits << name if body =~ regex || header_blob =~ regex
    end

    title = body[/<title[^>]*>(.*?)<\/title>/im, 1]
    hits << "Title: #{title.strip[0,80]}" if title && !title.strip.empty?

    hits.uniq.join(" | ")
  rescue
    "Unknown"
  end
end
