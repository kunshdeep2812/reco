require 'httparty'
require 'fileutils'
require 'colorize'
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
    end
  end
end

class Vhfind1
    OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
    def initialize
    end

    def domain_name(dname)
      @dname = dname
    end
    def thread_count(threads)
      @threads = threads
    end
    def fname(fn)
        @fn = fn
    end
    def change_uagent(agent)
      @agent = agent
    end
    def txtfile(filename)
      @filename = filename
    end
    def main_domain_file_list(domainlist)
        @domainlist = domainlist
    end

    def vscan
        domain = @dname
        thread1 = @threads
        filen = @fn
        $uagent = @agent
        $outp = @filename
        main_domain_file = @domainlist
        $r1 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.csv)$/
        $r2 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.txt)$/
        $r3 = /([a-zA-Z0-9\s_\\.\-\(\):])+(.pdf)$/
        if $outp !=nil
          case $outp
          when $r1
            puts " csv format currently not support for this script"
            exit
          when $r2
            $outp1 = $outp
          when $r3
            puts " pdf format currently not support for this script"
            exit
          else
            puts "Please provide valid file extension"
            exit
          end
        end
        if thread1 !=nil && thread1 != 0
          pool = ThreadPoolm01.new(thread1)
          else
           pool = ThreadPoolm01.new(10)
           #puts "Scan will run on default thread count to fast scan provide more thread count"
        end
        if filen !=nil
          filen1 = filen
          #puts filen1
        else
          filen1 = "./wordlist/host_word_list.txt"
          #puts filen1
        end
        timestmp = Time.now.utc.strftime("%Y-%m-%d")
        $path1 = "./Output/#{$outp1}:#{timestmp}"
        folderdir1 = FileUtils.mkdir_p($path1) unless File.exists?($path1)
        fln1 = File.readlines(filen1)
        if main_domain_file !=nil
          fln2 = File.readlines(main_domain_file)
          r1 = fln1.length
          s1 = fln2.length
          $progressbar.total = r1*s1
        else
          r1 = fln1.length
          $progressbar.total = r1
        end
#-------------------------------------------main domain list hit--------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------
        if main_domain_file !=nil
        File.open("#{main_domain_file}", 'r').each do |domain|
            regix = /^(?:(?>[a-z0-9-]*\.)+?|)([a-z0-9-]+\.(?>[a-z]*(?>\.[a-z]{2})?))$/i
            m_domain = domain.gsub(regix, '\1').strip
            domain.delete!(",\n")
            block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
            re = /\A#{block}\.#{block}\.#{block}\.#{block}\z/
            if domain.match(re)

#-------------------------------------------Keyword hit on domain-------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------            
            File.open("#{filen1}", 'r').each do |line|
              pool.schedule do
                sleep_time = 3
                sleep(sleep_time)
                line.delete!(",\n")
                if $uagent !=nil
                  if $uagent === "true"
                    myArray = ["Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:68.0) Gecko/20100101 Firefox/68.0", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.149 Safari/537.36", "Mozilla/5.0 (Linux; U; Android 2.3; en-us) AppleWebKit/999+ (KHTML, like Gecko) Safari/999.9", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1.2 Safari/605.1.15", "Mozilla/5.0 (Linux; Android 7.1.2; AFTMM Build/NS6265; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/70.0.3538.110 Mobile Safari/537.36", "Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148", "Mozilla/5.0 (X11; CrOS x86_64 12499.66.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.106 Safari/537.36" ]
                    xs = myArray.shuffle.first
                    #puts xs
                    headers = {
                      "Host" => "#{line}", #hostname
                      "User-Agent"  => "#{xs}",
                      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                      "Accept-Language" => "en-US,en;q=0.5",
                      "Accept-Encoding" => "gzip, deflate",
                      "DNT" => "1",
                      "Connection" => "close",
                      "Upgrade-Insecure-Requests" => "1"
                    }
                  else
                    #puts "asdsakljsaklsa sa sa sa sa"
                    headers = {
                      "Host" => "#{line}", #hostname
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
                    "Host" => "#{line}", #hostname
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
                    response = HTTParty.get("http://#{domain}", :headers => headers, :ciphers => 'HIGH:!DH:!aNULL', :verify => false, timeout: 5)
                    $progressbar.log("Status code: #{response.code}: ".yellow+"#{domain}:#{line}"+"    #{
                      ttt = response.headers
                      tttq = ttt.to_h
                      tttq.each do |v, t|end
                          
                    }".green)
                    rr1 = " Request headers"
                    rr2 = "#{response.request.last_uri.to_s}"
                     ttt = response.headers
                     tttq = ttt.to_h
                     rr3 = " Response headers"
                     rr4 = "\tStatus Code: #{response.code}: "+"\t"+"#{line}"
                    File.open("#{$path1}/#{$outp1}", "a") do |f|     
                      f.write("\n-----------------------------------------------------------------------------------------------\n"+"\n#{response.code}[Body Content-length: #{response.body.length}]\n"+"\t#{rr1}:-\n"+"\t\t#{rr2}\n"+"\t\t#{headers.each do |v, t| end}\n\n"+"\t#{rr3}:-\n"+"\t#{rr4}\n"+"\t\t#{tttq.each do |v, t|end}\n\n")   
                    end
                rescue => e
                  #$progressbar.log "#{line}.#{m_domain}:#{e}"
                  begin
                    response = HTTParty.get("https://#{domain}", :headers => headers, :ciphers => 'HIGH:!DH:!aNULL', :verify => false, timeout: 5)
                    $progressbar.log("Status code: #{response.code}: ".yellow+"#{domain}:#{line}"+"    #{
                      ttt = response.headers
                      tttq = ttt.to_h
                      tttq.each do |v, t|end
    
                    }".green)
                    rr1 = " Request headers"
                    rr2 = "#{response.request.last_uri.to_s}"
                     ttt = response.headers
                     tttq = ttt.to_h
                     rr3 = " Response headers"
                     rr4 = "\tStatus Code: #{response.code}: "+"\t"+"#{line}"
                    File.open("#{$path1}/#{$outp1}", "a") do |f|     
                      f.write("\n-----------------------------------------------------------------------------------------------\n"+"\n#{response.code}[Body Content-length: #{response.body.length}]\n"+"\t#{rr1}:-\n"+"\t\t#{rr2}\n"+"\t\t#{headers.each do |v, t| end}\n\n"+"\t#{rr3}:-\n"+"\t#{rr4}\n"+"\t\t#{tttq.each do |v, t|end}\n\n")   
                    end
                  rescue => e
                      #$progressbar.log "#{line}.#{m_domain}:#{e}"
                  end
                end
            end
          end

            else
#-------------------------------------------Keyword hit on domain-------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------            
            File.open("#{filen1}", 'r').each do |line|
                pool.schedule do
                  sleep_time = 3
                  sleep(sleep_time)
                  line.delete!(",\n")
                  if $uagent !=nil
                    if $uagent === "true"
                      myArray = ["Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:68.0) Gecko/20100101 Firefox/68.0", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.149 Safari/537.36", "Mozilla/5.0 (Linux; U; Android 2.3; en-us) AppleWebKit/999+ (KHTML, like Gecko) Safari/999.9", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1.2 Safari/605.1.15", "Mozilla/5.0 (Linux; Android 7.1.2; AFTMM Build/NS6265; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/70.0.3538.110 Mobile Safari/537.36", "Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148", "Mozilla/5.0 (X11; CrOS x86_64 12499.66.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.106 Safari/537.36" ]
                      xs = myArray.shuffle.first
                      #puts xs
                      headers = {
                        "Host" => "#{line}.#{m_domain}", #hostname
                        "User-Agent"  => "#{xs}",
                        "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                        "Accept-Language" => "en-US,en;q=0.5",
                        "Accept-Encoding" => "gzip, deflate",
                        "DNT" => "1",
                        "Connection" => "close",
                        "Upgrade-Insecure-Requests" => "1"
                      }
                    else
                      #puts "asdsakljsaklsa sa sa sa sa"
                      headers = {
                        "Host" => "#{line}.#{m_domain}", #hostname
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
                      "Host" => "#{line}.#{m_domain}", #hostname
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
                      response = HTTParty.get("http://#{domain}", :headers => headers, :ciphers => 'HIGH:!DH:!aNULL', :verify => false, timeout: 5)
                      $progressbar.log("Status code: #{response.code}: ".yellow+"#{line}.#{m_domain}"+"    #{
                        ttt = response.headers
                        tttq = ttt.to_h
                        tttq.each do |v, t|end
                            
                      }".green)
                      rr1 = " Request headers"
                      rr2 = "#{response.request.last_uri.to_s}"
                       ttt = response.headers
                       tttq = ttt.to_h
                       rr3 = " Response headers"
                       rr4 = "\tStatus Code: #{response.code}: "+"\t"+"#{line}.#{m_domain}"
                      File.open("#{$path1}/#{$outp1}", "a") do |f|     
                        f.write("\n-----------------------------------------------------------------------------------------------\n"+"\n#{response.code}[Body Content-length: #{response.body.length}]\n"+"\t#{rr1}:-\n"+"\t\t#{rr2}\n"+"\t\t#{headers.each do |v, t| end}\n\n"+"\t#{rr3}:-\n"+"\t#{rr4}\n"+"\t\t#{tttq.each do |v, t|end}\n\n")   
                      end
                  rescue => e
                    #$progressbar.log "#{line}.#{m_domain}:#{e}"
                    begin
                      response = HTTParty.get("https://#{domain}", :headers => headers, :ciphers => 'HIGH:!DH:!aNULL', :verify => false, timeout: 5)
                      $progressbar.log("Status code: #{response.code}: ".yellow+"#{line}.#{m_domain}"+"    #{
                        ttt = response.headers
                        tttq = ttt.to_h
                        tttq.each do |v, t|end
      
                      }".green)
                      rr1 = " Request headers"
                      rr2 = "#{response.request.last_uri.to_s}"
                       ttt = response.headers
                       tttq = ttt.to_h
                       rr3 = " Response headers"
                       rr4 = "\tStatus Code: #{response.code}: "+"\t"+"#{line}.#{m_domain}"
                      File.open("#{$path1}/#{$outp1}", "a") do |f|     
                        f.write("\n-----------------------------------------------------------------------------------------------\n"+"\n#{response.code}[Body Content-length: #{response.body.length}]\n"+"\t#{rr1}:-\n"+"\t\t#{rr2}\n"+"\t\t#{headers.each do |v, t| end}\n\n"+"\t#{rr3}:-\n"+"\t#{rr4}\n"+"\t\t#{tttq.each do |v, t|end}\n\n")   
                      end
                    rescue => e
                        #$progressbar.log "#{line}.#{m_domain}:#{e}"
                    end
                  end
              end
            end
            end
#-------------------------------------------main domain list hit--------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------
        end
#-------------------------------------------main domain list hit--------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------
         
      else
        regix = /^(?:(?>[a-z0-9-]*\.)+?|)([a-z0-9-]+\.(?>[a-z]*(?>\.[a-z]{2})?))$/i
        m_domain = domain.gsub(regix, '\1').strip
        File.open("#{filen1}", 'r').each do |line|
            pool.schedule do
              sleep_time = 3
              sleep(sleep_time)
              line.delete!(",\n")
              if $uagent !=nil
                if $uagent === "true"
                  myArray = ["Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:68.0) Gecko/20100101 Firefox/68.0", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.149 Safari/537.36", "Mozilla/5.0 (Linux; U; Android 2.3; en-us) AppleWebKit/999+ (KHTML, like Gecko) Safari/999.9", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1.2 Safari/605.1.15", "Mozilla/5.0 (Linux; Android 7.1.2; AFTMM Build/NS6265; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/70.0.3538.110 Mobile Safari/537.36", "Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148", "Mozilla/5.0 (X11; CrOS x86_64 12499.66.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.106 Safari/537.36" ]
                  xs = myArray.shuffle.first
                  #puts xs
                  headers = {
                    "Host" => "#{line}.#{m_domain}", #hostname
                    "User-Agent"  => "#{xs}",
                    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                    "Accept-Language" => "en-US,en;q=0.5",
                    "Accept-Encoding" => "gzip, deflate",
                    "DNT" => "1",
                    "Connection" => "close",
                    "Upgrade-Insecure-Requests" => "1"
                  }
                else
                  #puts "asdsakljsaklsa sa sa sa sa"
                  headers = {
                    "Host" => "#{line}.#{m_domain}", #hostname
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
                  "Host" => "#{line}.#{m_domain}", #hostname
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
                  response = HTTParty.get("http://#{domain}", :headers => headers, :ciphers => 'HIGH:!DH:!aNULL', :verify => false, timeout: 5)
                  $progressbar.log("Status code: #{response.code}: ".yellow+"#{line}.#{m_domain}"+"    #{
                    ttt = response.headers
                    tttq = ttt.to_h
                    tttq.each do |v, t|end
                        
                  }".green)
                  rr1 = " Request headers"
                  rr2 = "#{response.request.last_uri.to_s}"
                   ttt = response.headers
                   tttq = ttt.to_h
                   rr3 = " Response headers"
                   rr4 = "\tStatus Code: #{response.code}: "+"\t"+"#{line}.#{m_domain}"
                  File.open("#{$path1}/#{$outp1}", "a") do |f|     
                    f.write("\n-----------------------------------------------------------------------------------------------\n"+"\n#{response.code}[Body Content-length: #{response.body.length}]\n"+"\t#{rr1}:-\n"+"\t\t#{rr2}\n"+"\t\t#{headers.each do |v, t| end}\n\n"+"\t#{rr3}:-\n"+"\t#{rr4}\n"+"\t\t#{tttq.each do |v, t|end}\n\n")   
                  end
              rescue => e
                #puts "#{line}.#{m_domain}:#{e}"
                begin
                  response = HTTParty.get("https://#{domain}", :headers => headers, :ciphers => 'HIGH:!DH:!aNULL', :verify => false, timeout: 5)
                  $progressbar.log("Status code: #{response.code}: ".yellow+"#{line}.#{m_domain}"+"    #{
                    ttt = response.headers
                    tttq = ttt.to_h
                    tttq.each do |v, t|end
  
                  }".green)
                  rr1 = " Request headers"
                  rr2 = "#{response.request.last_uri.to_s}"
                   ttt = response.headers
                   tttq = ttt.to_h
                   rr3 = " Response headers"
                   rr4 = "\tStatus Code: #{response.code}: "+"\t"+"#{line}.#{m_domain}"
                  File.open("#{$path1}/#{$outp1}", "a") do |f|     
                    f.write("\n-----------------------------------------------------------------------------------------------\n"+"\n#{response.code}[Body Content-length: #{response.body.length}]\n"+"\t#{rr1}:-\n"+"\t\t#{rr2}\n"+"\t\t#{headers.each do |v, t| end}\n\n"+"\t#{rr3}:-\n"+"\t#{rr4}\n"+"\t\t#{tttq.each do |v, t|end}\n\n")   
                  end
                rescue => e
                  #puts "#{line}.#{m_domain}:#{e}"
                end
              end
          end
        end
#---------------------------------------- file not null of main domain hit list -----------------------------------------------------
     end
#---------------------------------------- file not null of main domain hit list -----------------------------------------------------
      if thread1 !=nil && thread1 !=0
        $progressbar.log "Thread count: #{Thread.list.count}"
      else
        $progressbar.log "Default thread count: #{Thread.list.count}"
      end
      pool.run!
    end
end
