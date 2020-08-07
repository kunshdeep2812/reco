#!/usr/bin/env ruby
require 'ipaddr'
require 'ipaddress'
require 'resolv'
require 'httparty'
require 'colorize'
require 'timeout'
require 'fileutils'
require 'ruby-progressbar'

$VERBOSE = nil
class ThreadPoolm11
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
              sleep 0.1
            end
          end
        end
      end
    end
  
    # add a job to queue
    def schedule(*args, &block)
      @jobs << [block, args]
    end
  
    # run threads and perform jobs from queue
    def run!
      @size.times do
        schedule { throw :exit }
      end
      abb = @pool.each.map{|t| t.join
        t.alive?
      }.none?
      if abb === true
        $progressbar.finish
        puts
        puts "\tScan Finished!"
        puts
      end
    end
  end

class Cidrportscanner

    OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
  
    def initialize

    end
    def range_addrs(ip1,ip2)
        @ip1 = ip1
        @ip2 = ip2
    end
    def thread_count(threads)
        @threads = threads
    end
    def cidr_range(cidr)
        @cidr = cidr
    end
    def scantypes(stypes)
        @scantypes = stypes
      end
      def prtnum(portnm)
        @portnm = portnm
      end
      def txtfile(filename)
        @filename = filename
      end
      def iprangefile(fname)
        @fname = fname
      end
      def singleiphit(snip)
        @sip = snip
      end
      def change_uagent(agent)
        @agent = agent
      end

    def cert(remote_host)
      ctx = OpenSSL::SSL::SSLContext.new
      begin 
        timeout(6) do
            sock = TCPSocket.new(remote_host, 443)
            ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
            ssl.connect
            cert = ssl.peer_cert
            return cert.subject.to_s
        end
    rescue
        #puts "Timed out!"
    end
      # puts cert.version
      # puts cert.subject.to_s
      # puts cert
    end
    def convert_ip_range(start_ip, end_ip)
      start_ip = IPAddr.new(start_ip)
      end_ip   = IPAddr.new(end_ip)
    (start_ip..end_ip).map(&:to_s)
    end
    def tests
        $a = 0
        t1 = @ip1
        t2 = @ip2
        cid = @cidr
        $ffname = @fname
        thread1 = @threads
        $scantype = @scantypes
        $portnum = @portnm
        $file1 = @filename
        singleip = @sip
        $uagent = @agent
        $r1 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.csv)$/
        $r2 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.txt)$/
        $r3 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.pdf)$/

        if $file1 !=nil
            #puts $file1
            case $file1

            when $r1
              timestmp = Time.now.utc.strftime("%Y-%m-%d")
              path1 = "./Output/#{$file1}:#{timestmp}"
              folderdir1 = FileUtils.mkdir_p(path1) unless File.exists?(path1)
              csv1 = CSV.open("#{path1}/#{$file1}", "a")
              csv1 << ['Status code','IP address with port number']
            when $r2
              #puts "file extension is txt"
              timestmp = Time.now.utc.strftime("%Y-%m-%d")
              path1 = "./Output/#{$file1}:#{timestmp}"
              folderdir1 = FileUtils.mkdir_p(path1) unless File.exists?(path1)
              txt1 = File.open("#{path1}/#{$file1}", "a")
              txt1 << "Status code\t"+"IP address with port number"+"\n"
            when $r3
              puts "PDF will not generate with this script"
              exit
            else
              puts "Please provide valid file extension"
              exit
            end
        end

        #puts cid
        if t1 !=nil && t2 !=nil
            ips = convert_ip_range(t1, t2)
            r1 = ips.length
        elsif cid !=nil
            ips1 = IPAddress.parse "#{cid}"
            f1 = ips1.first.to_s
            f2 = ips1.last.to_s
            #puts f1
            #puts f2
            ips = convert_ip_range(f1,f2)
            r1 = ips.length
        elsif $ffname !=nil
          ips = File.readlines($ffname)
          r1 = ips.length
        elsif singleip !=nil
          ips = singleip
          r1 = ips.length
        end

        if thread1 !=nil && thread1 != 0
            pool = ThreadPoolm11.new(thread1)
        else
             pool = ThreadPoolm11.new(10)
             #puts "Scan will run on default thread count to fast scan provide more thread count"
        end
        #$localip = /(^127\.)|(^192\.168\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)|(^::1$)|(^[fF][cCdD])/

        if $scantype !=nil
        case $scantype
        when 'full'
          $scanports = (1..65535)
          sz = $scanports.size
          $progressbar.total = r1*sz
        when 'top'
          $scanports = [80,443,3000,8080,4848,7001,8000,8005,8008,8181,8443,9000,9043,9060,9990]
          sz = $scanports.length
          $progressbar.total = r1*sz
        when 'custom'
          $scanports = $portnum
          #$progressbar.log"#{$scanports}"
          sz = $scanports.length
          $progressbar.total = r1*sz
       else
        $scanports = (1..1024)
        sz = $scanports.size
        $progressbar.total = r1*sz
      end
    else
        $scanports = (1..1024)
        sz = $scanports.size
          $progressbar.total = r1*sz
    end

        #threads = []
        ips.each do |domain|
          #puts domain
          $scanports.each do |port|
              pool.schedule do
                sleep_time = 2
                sleep(sleep_time)
                if $uagent != nil
                  if $uagent === "true"
                    myArray = ["Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:68.0) Gecko/20100101 Firefox/68.0", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.149 Safari/537.36", "Mozilla/5.0 (Linux; U; Android 2.3; en-us) AppleWebKit/999+ (KHTML, like Gecko) Safari/999.9", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1.2 Safari/605.1.15", "Mozilla/5.0 (Linux; Android 7.1.2; AFTMM Build/NS6265; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/70.0.3538.110 Mobile Safari/537.36", "Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148", "Mozilla/5.0 (X11; CrOS x86_64 12499.66.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.106 Safari/537.36" ]
                    xs = myArray.shuffle.first
                    #$progressbar.log xs
                    headers = { 
                      "User-Agent"  => "#{xs}",
                      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                      "Accept-Language" => "en-US,en;q=0.5",
                      "Accept-Encoding" => "gzip, deflate",
                      "DNT" => "1",
                      "Connection" => "close",
                      "Upgrade-Insecure-Requests" => "1"
                    }
                  else
                    #$progressbar.log "Wrong argument --randomagent. Running with default user-agent"
                    headers = { 
                      "User-Agent"  => "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:68.0) Gecko/20100101 Firefox/68.0",
                      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                      "Accept-Language" => "en-US,en;q=0.5",
                      "Accept-Encoding" => "gzip, deflate",
                      "DNT" => "1",
                      "Connection" => "close",
                      "Upgrade-Insecure-Requests" => "1"
                    }
                  end
                else
                  headers = { 
                    "User-Agent"  => "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:68.0) Gecko/20100101 Firefox/68.0",
                    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                    "Accept-Language" => "en-US,en;q=0.5",
                    "Accept-Encoding" => "gzip, deflate",
                    "DNT" => "1",
                    "Connection" => "close",
                    "Upgrade-Insecure-Requests" => "1"
                  }
                end
                begin
                  if $ffname !=nil
                    domain.delete!(",\r\n")
                    domain.to_s
                  end
                  if port === 80 || port === 443
                    response = HTTParty.get("http://#{domain}", :headers => headers, :ciphers => 'HIGH:!DH:!aNULL', :verify => false, timeout: 5)
                  else
                    response = HTTParty.get("http://#{domain}:#{port}", :headers => headers, :ciphers => 'HIGH:!DH:!aNULL', :verify => false, timeout: 5)
                  end
                  #$progressbar.log headers
                  $progressbar.log"\tWeb Portal: ".yellow+"#{domain}:".white+""+"#{port}".green
                  case $file1
                  when $r1
                      csv1 << ["#{response.code}","#{domain}:#{port}"]
                  when $r2
                  txt1 << "#{response.code}\t"+"#{domain}:#{port}"+"\n"
                  else
                end
                $a = $a + 1
              rescue => e
                #puts "#{domain}:#{port} => #{e}"
                begin
                  if $ffname !=nil
                    domain.delete!(",\r\n")
                    domain.to_s
                  end
                  if port === 80 || port === 443
                    response = HTTParty.get("https://#{domain}", :headers => headers, :ciphers => 'HIGH:!DH:!aNULL', :verify => false, timeout: 5)
                  else
                    response = HTTParty.get("https://#{domain}:#{port}", :headers => headers, :ciphers => 'HIGH:!DH:!aNULL', :verify => false, timeout: 5)
                  end
                  $progressbar.log"\tWeb Portal: ".yellow+"#{domain}:".white+""+"#{port}".green
                    case $file1
                    when $r1
                        csv1 << ["#{response.code}","#{domain}:#{port}"]
                    when $r2
                    txt1 << "#{response.code}\t"+"#{domain}:#{port}"+"\n"
                    else
                  end
                  $a = $a + 1
                rescue 
                end
              end
             end
          end
      end
      $progressbar.log"Thread count: #{Thread.list.count}"
      pool.run!
      #Thread.each {|a| a.join}
      puts "Count: "+"#{$a}"
      puts
    end
  
  end
