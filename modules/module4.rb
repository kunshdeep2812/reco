require 'selenium-webdriver'
require 'ipaddr'
require 'ipaddress'
require 'resolv'
require 'colorize'
require 'csv'
require 'httparty'
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
            sleep 0.2
            job, args = @jobs.pop
            job.call(*args)
            $progressbar.increment
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
      sleep 0.1
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

class Deepredirection
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
  #puts fname
end
  def cert(remote_host)
    ctx = OpenSSL::SSL::SSLContext.new
    begin 
        timeout(10) do
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

  def checkredirector
    $a = 0
    t1 = @ip1
    t2 = @ip2
    cid = @cidr
    $ffname = @fname  #range file name
    $file1 = @filename #file/folder name
    thread1 = @threads
    $r1 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.csv)$/
    $r2 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.txt)$/
    $r3 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.pdf)$/

    if t1 !=nil && t2 !=nil
      ips = convert_ip_range(t1, t2)
      r1 = ips.length
     # timestmp = Time.now.utc.strftime("%Y-%m-%d")
      #path = "../screenshot/#{r1}:#{timestmp}"
      #folderdir = FileUtils.mkdir_p(path) unless File.exists?(path)
    elsif cid !=nil
      ips1 = IPAddress.parse "#{cid}"
      f1 = ips1.first.to_s
      f2 = ips1.last.to_s
      ips = convert_ip_range(f1,f2)
      r1 = ips.length
      #timestmp = Time.now.utc.strftime("%Y-%m-%d")
     # path = "../screenshot/#{r1}:#{timestmp}"
     # folderdir = FileUtils.mkdir_p(path) unless File.exists?(path)
    elsif $ffname !=nil
    ips = File.readlines($ffname)
    r1 = ips.length
    #timestmp = Time.now.utc.strftime("%Y-%m-%d")
    #path = "../screenshot/#{r1}:#{timestmp}"
   # folderdir = FileUtils.mkdir_p(path) unless File.exists?(path)
    end

    if $file1 !=nil
      #puts $file1
    case $file1
    when $r1
      timestmp = Time.now.utc.strftime("%Y-%m-%d")
      path = "./screenshot/#{$file1}:#{timestmp}"
      path1 = "./Output/#{$file1}:#{timestmp}"
      folderdir = FileUtils.mkdir_p(path) unless File.exists?(path)
      folderdir1 = FileUtils.mkdir_p(path1) unless File.exists?(path1)
    csv1 = CSV.open("#{path1}/#{$file1}", "a")
    csv1 << ['Domain','Screenshot-name','Redirect url']
    when $r2
    #puts "file extension is txt"
    timestmp = Time.now.utc.strftime("%Y-%m-%d")
    path = "./screenshot/#{$file1}:#{timestmp}"
    path1 = "./Output/#{$file1}:#{timestmp}"
    folderdir = FileUtils.mkdir_p(path) unless File.exists?(path)
    folderdir1 = FileUtils.mkdir_p(path1) unless File.exists?(path1)
    txt1 = File.open("#{path1}/#{$file1}", "a")
    txt1 << "Domain\t\t"+"Screenshot-name\t\t"+" Redirect url"+"\n"
    when $r3
    puts "PDF will not generate with this script this time"
    else
    puts "\tIf you want an output so provide valid file extension"
    exit
    end
    end

    if thread1 !=nil && thread1 != 0
      pool = ThreadPoolm01.new(thread1)
      else
       pool = ThreadPoolm01.new(10)
       #puts "Scan will run on default thread count to fast scan provide more thread count"
    end
    $progressbar.total = r1
      headers = { 
        "User-Agent"  => "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:68.0) Gecko/20100101 Firefox/68.0",
        "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language" => "en-US,en;q=0.5",
        "Accept-Encoding" => "gzip, deflate",
        "DNT" => "1",
        "Connection" => "close",
        "Upgrade-Insecure-Requests" => "1"
      }
      
      ips.each do |domain|
        pool.schedule do
          sleep_time = 10
          sleep(sleep_time)
          begin
            if $ffname !=nil
              domain.delete!(",\r\n")
              domain.to_s
            end
            #jaskasdjasd
            response = HTTParty.get("http://#{domain}", :headers => headers, timeout: 10)
            if response.code != nil
              options = Selenium::WebDriver::Chrome::Options.new(args: ['--headless','--user-agent=Chrome/77','--disable-infobars','--disable-dev-shm-usage','--no-sandbox','--disable-extensions'])
              capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(accept_insecure_certs: true)
              driver = Selenium::WebDriver.for(:chrome, options: options, :desired_capabilities => capabilities)
              #driver.manage.timeouts.page_load = 10
              driver.get("http://#{domain}")
              driver.save_screenshot("#{path}/#{domain}-screenshot.png")
              $progressbar.log"\tDomain: ".yellow+"#{domain}\t"+"Final url: ".green+"#{driver.current_url}"
              if $file1 !=nil
                case $file1
                  when $r1
                      csv1 << ["#{domain}","#{path}/#{domain}-screenshot.png","#{driver.current_url}"]
                  when $r2
                  txt1 << "#{domain}\t\t"+"#{path}/#{domain}-screenshot.png\t\t"+"#{driver.current_url}\n"
                  else
                end
              end
              driver.close
              driver.quit
            end
            $a = $a + 1
          rescue => e
            #puts e
            begin
              if $ffname !=nil
                domain.delete!(",\r\n")
                domain.to_s
              end
              #sdsadasdas
              response = HTTParty.get("https://#{domain}", :headers => headers, :ciphers => 'HIGH:!DH:!aNULL', :verify => false, timeout: 10)
              if response.code != nil
                options = Selenium::WebDriver::Chrome::Options.new(args: ['--headless','--user-agent=Chrome/77','--disable-infobars','--disable-dev-shm-usage','--no-sandbox','--disable-extensions'])
                capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(accept_insecure_certs: true)
                driver = Selenium::WebDriver.for(:chrome, options: options, :desired_capabilities => capabilities)
                #driver.manage.timeouts.page_load = 10
                driver.get("https://#{domain}")
                driver.save_screenshot("#{path}/#{domain}-screenshot.png")
                $progressbar.log"\tDomain: ".yellow+"#{domain}\t"+"Final url: ".green+"#{driver.current_url}"
                if $file1 !=nil
                  case $file1
                    when $r1
                        csv1 << ["#{domain}","#{path}/#{domain}-screenshot.png","#{driver.current_url}"]
                    when $r2
                    txt1 << "#{domain}\t\t"+"#{path}/#{domain}-screenshot.png\t\t"+"#{driver.current_url}\n"
                    else
                  end
                end
                driver.close
                driver.quit
              end
              $a = $a + 1
            rescue 
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
