#!/usr/bin/env ruby
# DNS record recon: dump A/AAAA/MX/NS/TXT/CNAME/SOA records for a domain
require 'resolv'
require 'colorize'
require 'terminal-table'
require 'fileutils'
require 'csv'
$VERBOSE = nil

class Dnsrecon
  def initialize
  end

  def domain_name(dname)
    @dname = dname
  end
  def txtfile(filename)
    @filename = filename
  end
  def nameserver(ns)
    @ns = ns
  end

  RECORD_TYPES = {
    "A"     => Resolv::DNS::Resource::IN::A,
    "AAAA"  => Resolv::DNS::Resource::IN::AAAA,
    "MX"    => Resolv::DNS::Resource::IN::MX,
    "NS"    => Resolv::DNS::Resource::IN::NS,
    "TXT"   => Resolv::DNS::Resource::IN::TXT,
    "CNAME" => Resolv::DNS::Resource::IN::CNAME,
    "SOA"   => Resolv::DNS::Resource::IN::SOA
  }

  def lookup
    domain = @dname
    $file1 = @filename
    ns = @ns
    $r1 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.csv)$/
    $r2 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.txt)$/
    $r3 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.pdf)$/

    if domain.nil?
      puts "\tWarning: ".red + "Provide a domain with -d for dnsrecon"
      return
    end

    resolver = ns.nil? ? Resolv::DNS.new : Resolv::DNS.new(nameserver: [ns])

    results = []
    RECORD_TYPES.each do |type, rrclass|
      begin
        resolver.getresources(domain, rrclass).each do |rr|
          value =
            case type
            when "A", "AAAA"
              rr.address.to_s
            when "MX"
              "#{rr.preference} #{rr.exchange}"
            when "NS", "CNAME"
              rr.name.to_s
            when "TXT"
              rr.strings.join
            when "SOA"
              "#{rr.mname} #{rr.rname} serial=#{rr.serial} refresh=#{rr.refresh} retry=#{rr.retry} expire=#{rr.expire}"
            end
          results << [type, value]
        end
      rescue => e
        # record type not present / resolution error, skip
      end
    end
    resolver.close rescue nil

    if results.empty?
      puts "\tNo DNS records found for ".red + "#{domain}"
      puts
      return
    end

    table = Terminal::Table.new(
      title: "DNS records: #{domain}",
      headings: ['Type', 'Value'],
      rows: results
    )
    puts table
    puts "\tTotal records found: ".green + "#{results.length}"
    puts

    if $file1 != nil
      case $file1
      when $r1
        timestmp = Time.now.utc.strftime("%Y-%m-%d")
        path1 = "./Output/#{$file1}:#{timestmp}"
        FileUtils.mkdir_p(path1) unless File.exist?(path1)
        csv1 = CSV.open("#{path1}/#{$file1}", "a")
        csv1 << ['Record Type', 'Value']
        results.each { |r| csv1 << r }
      when $r2
        timestmp = Time.now.utc.strftime("%Y-%m-%d")
        path1 = "./Output/#{$file1}:#{timestmp}"
        FileUtils.mkdir_p(path1) unless File.exist?(path1)
        txt1 = File.open("#{path1}/#{$file1}", "a")
        txt1 << "Record Type\t\tValue\n"
        results.each { |r| txt1 << "#{r[0]}\t\t#{r[1]}\n" }
      when $r3
        puts "\tPDF will not generate with this script"
      else
        puts "\tIf you want an output so provide valid file extension"
      end
    end
  end
end
