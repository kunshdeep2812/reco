#!/usr/bin/env ruby
require 'ipaddr'
require 'ipaddress'
require 'resolv'
require 'openssl'
require 'httparty'
require 'colorize'
require 'csv'
require 'timeout'
require 'fileutils'
require 'ruby-progressbar'
$VERBOSE = nil
class ThreadPoolm01
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
              sleep 0.3
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
      end
    end
  end

class Rangescanner
    ciphers = 'HIGH:!DH:!aNULL'
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
    def txtfile(filename)
        @filename = filename
    end
    def iprangefile(fname)
      @fname = fname
    end
    def cert(remote_host)
      ciphers = 'HIGH:!DH:!aNULL'
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.set_params(verify_mode: OpenSSL::SSL::VERIFY_NONE)
      ctx.ciphers = ciphers
      begin 
        Timeout.timeout(10) do
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
        #puts thread1
        $file1 = @filename
        $r1 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.csv)$/
        $r2 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.txt)$/
        $r3 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.pdf)$/

            if t1 !=nil && t2 !=nil
                ips = convert_ip_range(t1, t2)
                r1 = ips.length
            elsif cid !=nil
                ips1 = IPAddress.parse "#{cid}"
                f1 = ips1.first.to_s
                f2 = ips1.last.to_s
                ips = convert_ip_range(f1,f2)
                r1 = ips.length
            elsif $ffname !=nil
              ips = File.readlines($ffname)
              r1 = ips.length
            end
        if $file1 !=nil
            #puts $file1
        case $file1
        when $r1
          timestmp = Time.now.utc.strftime("%Y-%m-%d")
          path1 = "./Output/#{$file1}:#{timestmp}"
          folderdir1 = FileUtils.mkdir_p(path1) unless File.exists?(path1)
          csv1 = CSV.open("#{path1}/#{$file1}", "a")
          csv1 << ['Status code','IP address','IP address Detail']

        when $r2
          #puts "file extension is txt"
          timestmp = Time.now.utc.strftime("%Y-%m-%d")
          path1 = "./Output/#{$file1}:#{timestmp}"
          folderdir1 = FileUtils.mkdir_p(path1) unless File.exists?(path1)
          txt1 = File.open("#{path1}/#{$file1}", "a")
          txt1 << "Status code\t"+"IP address\t\t"+"IP address Detail"+"\n"
        when $r3
          puts "PDF will not generate with this script"
        else
          puts "\tIf you want an output so provide valid file extension"
          exit
        end
        end
        $output = "No certificate"
        if thread1 !=nil && thread1 != 0
        pool = ThreadPoolm01.new(thread1)
        else
         pool = ThreadPoolm01.new(10)
         #puts "Scan will run on default thread count to fast scan provide more thread count"
        end
        $progressbar.total = r1
        headers = { 
          "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.89 Safari/537.36",
          "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
          "Sec-Fetch-Site" => "none",
          "Sec-Fetch-Mode" => "navigate",
          "Sec-Fetch-User" => "?1",
          "Sec-Fetch-Dest" => "document",
          "Accept-Encoding" => "gzip, deflate",
          "Accept-Language" => "en-US,en;q=0.9",
          "Upgrade-Insecure-Requests" => "1"
        }

        ips.each do |domain|
          pool.schedule do
            sleep_time = 3
            sleep(sleep_time)
            begin
              if $ffname !=nil
                domain.delete!(",\r\n")
                domain.to_s
              end
              #p domain
                response = HTTParty.get("http://#{domain}", :headers => headers, timeout: 10)
                $progressbar.log"\tStatus Code: #{response.code}".yellow+"\t"+"#{domain}".white+"\t\t"+"#{cert(domain)||"No certificate"}".green
                if $file1 !=nil
                  case $file1
                    when $r1
                        csv1 << ["#{response.code}","#{domain}","#{cert(domain)||$output}"]
                    when $r2
                    txt1 << "#{response.code}\t\t"+"#{domain}\t\t"+"#{cert(domain)||$output}"+"\n"
                    else
                  end
                end
                $a = $a + 1
            rescue => e
              #$progressbar.log "#{domain}:\t\t #{e}"
              begin
                if $ffname !=nil
                  domain.delete!(",\r\n")
                  domain.to_s
                end
                response = HTTParty.get("https://#{domain}", :headers => headers, :ciphers => 'HIGH:!DH:!aNULL', :verify => false, timeout: 10)
                $progressbar.log"\tStatus Code: #{response.code}".yellow+"\t"+"#{domain}".white+"\t\t"+"#{cert(domain)||"No certificate"}".green
                if $file1 !=nil
                   case $file1
                     when $r1
                         csv1 << ["#{response.code}","#{domain}","#{cert(domain)}"]
                     when $r2
                     txt1 << "#{response.code}\t\t"+"#{domain}\t\t"+"#{cert(domain)}"+"\n"
                     else
                   end
                end
                $a = $a + 1
              rescue Errno::ECONNREFUSED
                ciphers = 'HIGH:!DH:!aNULL'
                ctx = OpenSSL::SSL::SSLContext.new
                ctx.set_params(verify_mode: OpenSSL::SSL::VERIFY_NONE)
                ctx.ciphers = ciphers
                begin
                  Timeout.timeout(10) do
                    sock = TCPSocket.new(domain, 443)
                    ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
                    ssl.connect
                    cert = ssl.peer_cert
                    $progressbar.log "Error:-#{e}:\t#{domain}:\t #{cert.subject.to_s}"
                end
                rescue 
                end
              rescue => e
                if e.message =~ /^execution expired/
                elsif e.message =~ /^end of file reached/
                  ciphers = 'HIGH:!DH:!aNULL'
                  ctx = OpenSSL::SSL::SSLContext.new
                  ctx.set_params(verify_mode: OpenSSL::SSL::VERIFY_NONE)
                  ctx.ciphers = ciphers
                  begin
                    Timeout.timeout(10) do
                      sock = TCPSocket.new(domain, 443)
                      ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
                      ssl.connect
                      cert = ssl.peer_cert
                      $progressbar.log "Error:-#{e}:\t#{domain}:\t #{cert.subject.to_s}"
                  end
                  rescue
                    
                  end
                elsif e.message =~ /^Net::ReadTimeout/
                  ciphers = 'HIGH:!DH:!aNULL'
                  ctx = OpenSSL::SSL::SSLContext.new
                  ctx.set_params(verify_mode: OpenSSL::SSL::VERIFY_NONE)
                  ctx.ciphers = ciphers
                  begin
                    Timeout.timeout(10) do
                      sock = TCPSocket.new(domain, 443)
                      ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
                      ssl.connect
                      cert = ssl.peer_cert
                      $progressbar.log "Error:-#{e}:\t#{domain}:\t #{cert.subject.to_s}"
                  end
                  rescue

                  end
                else
                  #$progressbar.log "#{domain}:\t\t #{e}"
                end
              end
            end
          end
      end
      if thread1 !=nil && thread1 !=0
        $progressbar.log "Thread count: #{Thread.list.count}"
      else
        $progressbar.log "Default thread count: #{Thread.list.count}"
      end
      pool.run!
      puts "\tTotal Working IP count: "+"#{$a}"
      puts
    end
    

end
