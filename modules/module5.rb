#!/usr/bin/env ruby
# Subdomain enumeration: passive (crt.sh certificate transparency) + active (DNS bruteforce)
require 'httparty'
require 'resolv'
require 'colorize'
require 'json'
require 'csv'
require 'fileutils'
require 'ruby-progressbar'
require './modules/fingerprint.rb'
$VERBOSE = nil

class ThreadPoolm05
  def initialize(size)
    $progressbar = ProgressBar.create(total: nil, length: 150, format: "In Progress: %c/%C |\e[31m%B\e[0m| %a %e")
    @size = size
    @jobs = Queue.new
    @pool = Array.new(@size) do |i|
      Thread.new do
        Thread.current[:id] = i
        catch(:exit) do
          loop do
            job, args = @jobs.pop
            job.call(*args)
            $progressbar.increment
            sleep 0.05
          end
        end
      end
    end
  end

  def schedule(*args, &block)
    @jobs << [block, args]
  end

  def run!
    @size.times do
      schedule { throw :exit }
    end
    abb = @pool.each.map { |t| t.join; t.alive? }.none?
    if abb === true
      $progressbar.finish
      puts
      puts "\tScan Finished!"
    end
  end
end

class Subenum
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  def initialize
  end

  def domain_name(dname)
    @dname = dname
  end
  def wordlist_file(fn)
    @fn = fn
  end
  def thread_count(threads)
    @threads = threads
  end
  def txtfile(filename)
    @filename = filename
  end
  def subtype(stype)
    @stype = stype
  end

  # Passive lookup via crt.sh certificate transparency logs
  def passive_lookup(domain)
    found = []
    begin
      response = HTTParty.get("https://crt.sh/?q=%25.#{domain}&output=json", timeout: 20)
      if response.code == 200 && !response.body.to_s.strip.empty?
        data = (JSON.parse(response.body) rescue [])
        data.each do |entry|
          entry["name_value"].to_s.split("\n").each do |name|
            name = name.strip.downcase.sub(/\A\*\./, "")
            found << name if !name.empty? && (name == domain || name.end_with?(".#{domain}"))
          end
        end
      end
    rescue => e
      puts "\tWarning: ".red + "Passive lookup(crt.sh) failed: #{e.message}"
    end
    found.uniq
  end

  def enum
    domain = @dname
    thread1 = @threads
    $file1 = @filename
    stype = @stype || "full"
    wl = @fn || "./wordlist/host_word_list.txt"
    $r1 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.csv)$/
    $r2 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.txt)$/
    $r3 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.pdf)$/

    if $file1 != nil
      case $file1
      when $r1
        timestmp = Time.now.utc.strftime("%Y-%m-%d")
        path1 = "./Output/#{$file1}:#{timestmp}"
        FileUtils.mkdir_p(path1) unless File.exist?(path1)
        csv1 = CSV.open("#{path1}/#{$file1}", "a")
        csv1 << ['Subdomain', 'IP address', 'HTTP Status', 'Fingerprint', 'Source']
      when $r2
        timestmp = Time.now.utc.strftime("%Y-%m-%d")
        path1 = "./Output/#{$file1}:#{timestmp}"
        FileUtils.mkdir_p(path1) unless File.exist?(path1)
        txt1 = File.open("#{path1}/#{$file1}", "a")
        txt1 << "Subdomain\t\t" + "IP address\t\t" + "HTTP Status\t\t" + "Fingerprint\t\t" + "Source" + "\n"
      when $r3
        puts "\tPDF will not generate with this script"
      else
        puts "\tIf you want an output so provide valid file extension"
        exit
      end
    end

    candidates = {}

    if stype == "passive" || stype == "full"
      puts "\tRunning passive enumeration (crt.sh)...".yellow
      plist = passive_lookup(domain)
      plist.each { |d| candidates[d] = "passive" }
      puts "\tPassive sources found: ".green + "#{plist.length}"
      puts
    end

    if stype == "active" || stype == "full"
      if !File.exist?(wl)
        puts "\tWarning: ".red + "Wordlist file not found: #{wl}"
      else
        File.readlines(wl).each do |w|
          w = w.strip
          next if w.empty?
          sub = "#{w}.#{domain}"
          candidates[sub] ||= "active"
        end
      end
    end

    candidates[domain] ||= "root"

    if thread1 != nil && thread1 != 0
      pool = ThreadPoolm05.new(thread1)
    else
      pool = ThreadPoolm05.new(20)
    end
    $progressbar.total = candidates.length

    $a = 0
    mutex = Mutex.new
    headers = {
      "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.89 Safari/537.36"
    }

    candidates.each do |sub, source|
      pool.schedule do
        begin
          ip = Resolv.getaddress(sub)
          status = "-"
          fp = "-"
          begin
            resp = HTTParty.get("http://#{sub}", headers: headers, timeout: 6)
            status = resp.code.to_s
            fp = Fingerprint.identify(resp)
          rescue
            begin
              resp = HTTParty.get("https://#{sub}", headers: headers, verify: false, timeout: 6)
              status = resp.code.to_s
              fp = Fingerprint.identify(resp)
            rescue
            end
          end
          mutex.synchronize { $a += 1 }
          $progressbar.log "\tSubdomain: ".yellow + "#{sub}".white + "\t" + "#{ip}".green + "\t" + "#{status}".cyan + "\t[#{source}]".magenta + "\t#{fp}"
          if $file1 != nil
            case $file1
            when $r1
              csv1 << [sub, ip, status, fp, source]
            when $r2
              txt1 << "#{sub}\t\t#{ip}\t\t#{status}\t\t#{fp}\t\t#{source}\n"
            end
          end
        rescue Resolv::ResolvError, Resolv::ResolvTimeout
          # not resolvable, skip silently
        rescue => e
        end
      end
    end

    pool.run!
    puts "\tTotal live subdomains found: " + "#{$a}"
    puts
  end
end
