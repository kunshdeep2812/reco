#!/usr/bin/env ruby
# Version: 0.0.3
require 'optparse'
require 'colorize'
require 'terminal-table'
require './modules/banner.rb'
require './modules/module0.rb'
require './modules/module1.rb'
require './modules/module2.rb'
require './modules/module3.rb'
require './modules/module4.rb'
$VERBOSE = nil
ban = Banner.new
ban.banner

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: ruby #{$0} ".white + "--script [".green + "OPTIONS".white + "] ".green + "..[".green + "OPTIONS".white + "]".green
  opts.separator ""
  opts.separator "How to use: ".green + "#{$0} ".yellow+"--script rangescan -s 192.0.0.1 -e 192.0.0.255 --thread 10".white
  opts.separator "How to use: ".green + "#{$0} ".yellow+"--script portscan --ip 192.168.0.6 --scantype custom -p 80,443,23 --thread 40".white
  opts.separator "How to use: ".green + "#{$0} ".yellow+"--script rangescan -r 192.168.0.1/24 -o test.csv --thread 10".white
  opts.separator "How to use: ".green + "#{$0} ".yellow+"--script portscan --iL /home/test/example.txt --randomagent true --thread 50 -o example.txt".white
  opts.separator "How to use: ".green + "#{$0} ".yellow+"--script echotest --socketurl wss://example.com".white
  opts.separator "How to use: ".green + "#{$0} ".yellow+"--help".white
  opts.separator ""
  opts.separator "For more please check the ".green+"commands.txt".yellow+" file".green
  #opts.separator "EX".green + ": #{$0} --single '192.168.3-5.1-254'".white
  opts.separator ""
  opts.separator "Options".green + ": ".white
  opts.on('-s', '--startIPAddress ', "Provide Starting IPaddress\n".white) do |start_ip|
      options[:method1]
      options[:startingIP] = start_ip.strip.chomp
  end
  opts.on('-e', '--endIPAddress ', "Provide ending IPaddress\n".white) do |end_ip|
    options[:method2]
    options[:endingIP] = end_ip.strip.chomp
  end
  opts.on('-o', '--output ', "Provide filename with extension(.txt)\n".white) do |file_name|
    options[:method3]
    options[:filename] = file_name.strip.chomp
  end
  opts.on('-w', '--wordlist ', "Provide filename which contains wordlist\n".white) do |word_list|
    options[:method4]
    options[:wordlist] = word_list.strip.chomp
  end
  opts.on('-d', '--domain ', "Provide domain name for bruteforce subdomain\n".white) do |domain_name|
    options[:method5]
    options[:domainname] = domain_name.strip.chomp
  end
  opts.on('-r', '--ipRange ', "Provide IpAddress Range (e.g.: 192.0.168.1/24)\n".white) do |ip_range|
    options[:method6]
    options[:ipRange] = ip_range.strip.chomp
  end
  opts.on('--randomagent ', "For random user-agent, set --randomagent true\n".white) do |randomagent|
    options[:method7]
    options[:randomagent] = randomagent.strip.chomp
  end
  opts.on('--socketurl ', "Provide socket initiation url\n".white) do |socket_url|
    options[:method8]
    options[:socketurl] = socket_url.strip.chomp
  end
  opts.on('--iL ', "provide the list of ipaddress/domain-name file\n".white) do |ilfile|
    options[:method9]
    options[:ilfile] = ilfile.strip.chomp
  end
  opts.on('--ip ', "provide single Ip\n".white) do |single_ip|
    options[:method10]
    options[:singleIP] = single_ip.strip.chomp
  end
  opts.on('--thread ', "provide number of threads\n".white) do |thread|
    options[:method11]
    options[:thread] = thread.strip.chomp
  end
  opts.on('--script ', "provide specific script name\n".white) do |script|
    options[:method12]
    options[:script] = script.strip.chomp
  end
  opts.on('--scantype ', "provide port scan type (full, top, custom)\n".white) do |portype|
    options[:method13]
    options[:scantype] = portype.strip.chomp
  end
  opts.on('-p', '--port ', "Provide single or multiple port to scan\n".white) do |defport|
    options[:method14]
    options[:defport] = defport.strip.chomp
  end
  
script_options = Terminal::Table.new(

  rows: [
    ["rangescan","Scan the ips/cidr range"],
    ["vhostscan","To find virtual host of single domain/ip's"],
    ["portscan","To find open ports of single/multiple's domain/ip's"],
    ["echotest","To check if the websocket is vulnerable from Cross-Site WebSocket Hijacking"],
    ["redirect-scr","To find deep redirection and screenshot of given domain/ip address"]
  ],

  headings: [
    'Script Name',
    'Script Description'
  ],
  style: { }

)
  opts.on('-h', '--help', "Help Menu\n".white) do
    puts
    puts opts
    puts
    exit 69;
  end
  opts.on('--scriptlist', "List of scripts or modules\n".white) do
    puts
    puts script_options
    puts
    exit 69;
  end
end
begin
    foo = ARGV[0] || ARGV[0] = " " # nothing passed, send to help menu
    optparse.parse!
    mandatory = [ :method1]
    mandatory2 = [ :method2]
    mandatory3 = [ :method3]
    mandatory4 = [ :method4]
    mandatory5 = [ :method5]
    mandatory6 = [ :method6]
    mandatory7 = [ :method7]
    mandatory8 = [ :method8]
    mandatory9 = [ :method9]
    mandatory10 = [ :method10]
    mandatory11 = [ :method11]
    mandatory12 = [ :method12]
    mandatory13 = [ :method13]
    mandatory14 = [ :method14]
    missing = mandatory.select{ |param| options[param].nil? }
    missing2 = mandatory2.select{ |param| options[param].nil? }
    missing3 = mandatory3.select{ |param| options[param].nil? }
    missing4 = mandatory4.select{ |param| options[param].nil? }
    missing5 = mandatory5.select{ |param| options[param].nil? }
    missing6 = mandatory6.select{ |param| options[param].nil? }
    missing7 = mandatory7.select{ |param| options[param].nil? }
    missing8 = mandatory8.select{ |param| options[param].nil? }
    missing9 = mandatory9.select{ |param| options[param].nil? }
    missing10 = mandatory10.select{ |param| options[param].nil? }
    missing11 = mandatory11.select{ |param| options[param].nil? }
    missing12 = mandatory12.select{ |param| options[param].nil? }
    missing13 = mandatory13.select{ |param| options[param].nil? }
    missing14 = mandatory14.select{ |param| options[param].nil? }

  rescue OptionParser::InvalidOption, OptionParser::MissingArgument, OptionParser::AmbiguousOption
    puts $!.to_s.red
    puts
    puts optparse
    puts
    puts
    exit 666;
  end

ARGV[0] = " "

$x1 = options[:startingIP]
$x2 = options[:endingIP]
$x3 = options[:wordlist]
$x4 = options[:domainname]
$x5 = options[:filename]
$x6 = options[:ipRange]
$x7 = options[:randomagent]
$x8 = options[:socketurl]
$x9 = options[:ilfile]
$x10 = options[:singleIP]
$x11 = options[:thread]
$x12 = options[:script]
$x13 = options[:scantype]
$x14 = options[:defport]
  #puts $x1 + $x2
  #websocket hijack
if $x12 !=nil
  case $x12

  #Range scan ip's and  domain name----------------------------------------------------------------------------------------  
  when "rangescan"
    if $x1 != nil && $x2 != nil && $x6 !=nil
      puts "\tWarning: ".red+"Please provide either (-s 0.0.0.0 -e 0.0.0.0) range of ip addresses or (-r 0.0.0.0/24) cidr notation"
      puts
      puts "\tUsage: ruby #{$0} ".white + "[".green + "OPTIONS".white + "] ".green + " -h ".green + " or " + " --help".green
      puts
      exit
      else
          if $x1 != nil && $x2 != nil
              if $x11 !=nil || $x5 !=nil
                  a = Rangescanner.new
                  a.range_addrs($x1,$x2)
                  a.txtfile($x5)
                  a.thread_count($x11.to_i)
                  a.tests
              else  
                a = Rangescanner.new
                a.range_addrs($x1,$x2)
                a.tests
              end
            elsif $x6 !=nil
              if $x11 !=nil || $x5 !=nil
                  a = Rangescanner.new
                  a.cidr_range($x6)
                  a.thread_count($x11.to_i)
                  a.txtfile($x5)
                  a.tests
              else
                a = Rangescanner.new
                a.cidr_range($x6)
                a.tests
              end
            elsif $x9 !=nil
               if $x11 !=nil || $x5 !=nil
                a = Rangescanner.new
                a.iprangefile($x9)
                a.thread_count($x11.to_i)
                a.txtfile($x5)
                a.tests
              else
              a = Rangescanner.new
              a.iprangefile($x9)
              a.tests
              end
            else
              puts "provide range scan arguments"
           end
      end
  
  #Web Port scan module--------------------------------------------------------------------------------------------------

  when "portscan"
    if $x13 !=nil

      if ($x1 != nil && $x2 != nil && $x6 !=nil) || ($x1 !=nil && $x2 !=nil && $x9 !=nil) || ($x6 !=nil && $x9 !=nil)
        puts "\tWarning: ".red+"Please provide either (-s 0.0.0.0 -e 0.0.0.0) range of ip addresses or (-r 0.0.0.0/24) cidr notation or file name contains(-iL iplist.txt) ip address"
        puts
        puts "\tUsage: ruby #{$0} ".white + "[".green + "OPTIONS".white + "] ".green + " -h ".green + " or " + " --help".green
        puts
        exit
      else
        case $x13
        when 'full'
          if $x1 != nil && $x2 != nil
              if $x11 !=nil || $x5 !=nil
                if $x7 !=nil
                  a = Cidrportscanner.new
                  a.range_addrs($x1,$x2)
                  a.txtfile($x5)
                  a.scantypes($x13)
                  a.thread_count($x11.to_i)
                  a.change_uagent($x7)
                  a.tests
                else
                  a = Cidrportscanner.new
                  a.range_addrs($x1,$x2)
                  a.txtfile($x5)
                  a.scantypes($x13)
                  a.thread_count($x11.to_i)
                  a.tests
                end
              else  
                a = Cidrportscanner.new
                a.range_addrs($x1,$x2)
                a.scantypes($x13)
                a.tests
              end
            elsif $x6 !=nil
              if $x11 !=nil || $x5 !=nil
                if $x7 !=nil
                  a = Cidrportscanner.new
                  a.cidr_range($x6)
                  a.thread_count($x11.to_i)
                  a.scantypes($x13)
                  a.txtfile($x5)
                  a.change_uagent($x7)
                  a.tests
                else
                  a = Cidrportscanner.new
                  a.cidr_range($x6)
                  a.thread_count($x11.to_i)
                  a.scantypes($x13)
                  a.txtfile($x5)
                  a.tests
                end
              else
                a = Cidrportscanner.new
                a.cidr_range($x6)
                a.tests
              end
            elsif $x9 !=nil
               if $x11 !=nil || $x5 !=nil
                if $x7 !=nil
                  a = Cidrportscanner.new
                  a.iprangefile($x9)
                  a.thread_count($x11.to_i)
                  a.txtfile($x5)
                  a.scantypes($x13)
                  a.change_uagent($x7)
                  a.tests
                else
                  a = Cidrportscanner.new
                  a.iprangefile($x9)
                  a.thread_count($x11.to_i)
                  a.txtfile($x5)
                  a.scantypes($x13)
                  a.tests
                end
              else
              a = Cidrportscanner.new
              a.iprangefile($x9)
              a.scantypes($x13)
              a.tests
              end
            elsif $x10 !=nil
              singip = $x10.split(/,/).to_a
              block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
              re = /\A#{block}\.#{block}\.#{block}\.#{block}\z/
              if singip.all? {|i| i.match(re) }
                xb11 = singip.each.map(&:to_s)
                #p xb11
                if $x5 !=nil || $x11 !=nil
                  if $x7 !=nil
                    a2 = Cidrportscanner.new
                    a2.singleiphit(xb11)
                    a2.thread_count($x11.to_i)
                    a2.txtfile($x5)
                    a2.scantypes($x13)
                    a2.change_uagent($x7)
                    a2.tests
                  else
                    a2 = Cidrportscanner.new
                    a2.singleiphit(xb11)
                    a2.thread_count($x11.to_i)
                    a2.txtfile($x5)
                    a2.scantypes($x13)
                    a2.tests
                  end
                else
                  a2 = Cidrportscanner.new
                  a2.singleiphit(xb11)
                  a2.scantypes($x13)
                  a2.tests
                end
              else
                puts "\tWarning: ".red+"You have provided some wrong ip address"
              end

            else
              puts "provide web port scan arguments lol"
           end
        when 'top'
          if $x1 != nil && $x2 != nil
              if $x11 !=nil || $x5 !=nil
                if $x7 !=nil
                  a = Cidrportscanner.new
                  a.range_addrs($x1,$x2)
                  a.txtfile($x5)
                  a.scantypes($x13)
                  a.thread_count($x11.to_i)
                  a.change_uagent($x7)
                  a.tests
                else
                  a = Cidrportscanner.new
                  a.range_addrs($x1,$x2)
                  a.txtfile($x5)
                  a.scantypes($x13)
                  a.thread_count($x11.to_i)
                  a.tests
                end
              else  
                a = Cidrportscanner.new
                a.range_addrs($x1,$x2)
                a.scantypes($x13)
                a.tests
              end
            elsif $x6 !=nil
              if $x11 !=nil || $x5 !=nil
                if $x7 !=nil
                  a = Cidrportscanner.new
                  a.cidr_range($x6)
                  a.thread_count($x11.to_i)
                  a.scantypes($x13)
                  a.txtfile($x5)
                  a.change_uagent($x7)
                  a.tests
                else
                  a = Cidrportscanner.new
                  a.cidr_range($x6)
                  a.thread_count($x11.to_i)
                  a.scantypes($x13)
                  a.txtfile($x5)
                  a.tests
                end
              else
                a = Cidrportscanner.new
                a.cidr_range($x6)
                a.tests
              end
            elsif $x9 !=nil
               if $x11 !=nil || $x5 !=nil
                if $x7 !=nil
                  a = Cidrportscanner.new
                  a.iprangefile($x9)
                  a.thread_count($x11.to_i)
                  a.txtfile($x5)
                  a.scantypes($x13)
                  a.change_uagent($x7)
                  a.tests
                else
                  a = Cidrportscanner.new
                  a.iprangefile($x9)
                  a.thread_count($x11.to_i)
                  a.txtfile($x5)
                  a.scantypes($x13)
                  a.tests
                end
              else
              a = Cidrportscanner.new
              a.iprangefile($x9)
              a.scantypes($x13)
              a.tests
              end
            elsif $x10 !=nil
              singip = $x10.split(/,/).to_a
              block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
              re = /\A#{block}\.#{block}\.#{block}\.#{block}\z/
              if singip.all? {|i| i.match(re) }
                xb11 = singip.each.map(&:to_s)
                if $x5 !=nil || $x11 !=nil
                  if $x7 !=nil
                    a2 = Cidrportscanner.new
                    a2.singleiphit(xb11)
                    a2.thread_count($x11.to_i)
                    a2.txtfile($x5)
                    a2.scantypes($x13)
                    a2.change_uagent($x7)
                    a2.tests
                  else
                    a2 = Cidrportscanner.new
                    a2.singleiphit(xb11)
                    a2.thread_count($x11.to_i)
                    a2.txtfile($x5)
                    a2.scantypes($x13)
                    a2.tests
                  end
                else
                  a2 = Cidrportscanner.new
                  a2.singleiphit(xb11)
                  a2.scantypes($x13)
                  a2.tests
                end
              else
                puts "\tWarning: ".red+"You have provided some wrong ip address"
              end
            else
              puts "provide web port scan arguments"
           end
        when 'custom'
          if $x14 !=nil
            xa = $x14.split(/,/).to_a
            if xa.all? {|i| i.match(/\A[+-]?\d+?(_?\d+)*(\.\d+e?\d*)?\Z/) }
                xb = xa.each.map(&:to_i)
                if $x1 != nil && $x2 != nil
                  if $x11 !=nil || $x5 !=nil
                    if $x7 !=nil
                      a = Cidrportscanner.new
                      a.range_addrs($x1,$x2)
                      a.txtfile($x5)
                      a.scantypes($x13)
                      a.prtnum(xb)
                      a.change_uagent($x7)
                      a.thread_count($x11.to_i)
                      a.tests
                    else
                      a = Cidrportscanner.new
                      a.range_addrs($x1,$x2)
                      a.txtfile($x5)
                      a.scantypes($x13)
                      a.prtnum(xb)
                      a.thread_count($x11.to_i)
                      a.tests
                    end

                  else  
                    a = Cidrportscanner.new
                    a.range_addrs($x1,$x2)
                    a.scantypes($x13)
                    a.prtnum(xb)
                    a.tests
                  end
                elsif $x6 !=nil
                  if $x11 !=nil || $x5 !=nil
                    if $x7 !=nil
                      a = Cidrportscanner.new
                      a.cidr_range($x6)
                      a.thread_count($x11.to_i)
                      a.scantypes($x13)
                      a.prtnum(xb)
                      a.change_uagent($x7)
                      a.txtfile($x5)
                      a.tests
                    else
                      a = Cidrportscanner.new
                      a.cidr_range($x6)
                      a.thread_count($x11.to_i)
                      a.scantypes($x13)
                      a.prtnum(xb)
                      a.txtfile($x5)
                      a.tests
                    end
                  else
                    a = Cidrportscanner.new
                    a.cidr_range($x6)
                    a.scantypes($x13)
                    a.prtnum(xb)
                    a.tests
                  end
                elsif $x9 !=nil
                   if $x11 !=nil || $x5 !=nil
                    if $x7 !=nil
                      a = Cidrportscanner.new
                      a.iprangefile($x9)
                      a.thread_count($x11.to_i)
                      a.txtfile($x5)
                      a.prtnum(xb)
                      a.scantypes($x13)
                      a.change_uagent($x7)
                      a.tests
                    else
                      a = Cidrportscanner.new
                      a.iprangefile($x9)
                      a.thread_count($x11.to_i)
                      a.txtfile($x5)
                      a.prtnum(xb)
                      a.scantypes($x13)
                      a.tests
                    end
                  else
                  a = Cidrportscanner.new
                  a.iprangefile($x9)
                  a.prtnum(xb)
                  a.scantypes($x13)
                  a.tests
                  end
                elsif $x10 !=nil
                  singip = $x10.split(/,/).to_a
                  block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
                  re = /\A#{block}\.#{block}\.#{block}\.#{block}\z/
                  if singip.all? {|i| i.match(re) }
                    xb11 = singip.each.map(&:to_s)
                    #puts "test"
                    #puts singip
                    if $x5 !=nil || $x11 !=nil
                      if $x7 !=nil
                        a2 = Cidrportscanner.new
                        a2.singleiphit(xb11)
                        a2.thread_count($x11.to_i)
                        a2.txtfile($x5)
                        a2.prtnum(xb)
                        a2.scantypes($x13)
                        a2.change_uagent($x7)
                        a2.tests
                      else
                        a2 = Cidrportscanner.new
                        a2.singleiphit(xb11)
                        a2.thread_count($x11.to_i)
                        a2.txtfile($x5)
                        a2.prtnum(xb)
                        a2.scantypes($x13)
                        a2.tests
                      end
                    else
                      a2 = Cidrportscanner.new
                      a2.singleiphit(xb11)
                      a2.prtnum(xb)
                      a2.scantypes($x13)
                      a2.tests
                    end
                  else
                    #puts singip
                    puts "\tWarning: ".red+"You have provided some wrong ip address"
                  end
                else
                  puts "\tWarning: ".red+"provide web port scan arguments"
                  puts
               end

            else 
                puts "\tWarning: ".red+"You have pass some non valid port"
                puts
                exit
            end
            


         else
          puts "\tWith the custom scan type you have to provide the port's(-p 80,443,8080,8443)"
          puts
          end
       else
        puts "\tWarning: ".red+"Provide valid scan type\n"
        puts
        puts "\tUsage: ruby #{$0} ".white + "[".green + "OPTIONS".white + "] ".green + " -h ".green + " or " + " --help".green
        puts
        puts
      end
      end
    else
     if ($x1 != nil && $x2 != nil && $x6 !=nil) || ($x1 !=nil && $x2 !=nil && $x9 !=nil) || ($x6 !=nil && $x9 !=nil)
      puts "\tWarning: ".red+"Please provide either (-s 0.0.0.0 -e 0.0.0.0) range of ip addresses or (-r 0.0.0.0/24) cidr notation or file name contains(-iL iplist.txt) ip address"
      puts
      puts "\tUsage: ruby #{$0} ".white + "[".green + "OPTIONS".white + "] ".green + " -h ".green + " or " + " --help".green
      puts
      exit
     else
          if $x1 != nil && $x2 != nil
              if $x11 !=nil || $x5 !=nil
                if $x7 !=nil
                  a = Cidrportscanner.new
                  a.range_addrs($x1,$x2)
                  a.txtfile($x5)
                  a.thread_count($x11.to_i)
                  a.change_uagent($x7)
                  a.tests
                else
                  a = Cidrportscanner.new
                  a.range_addrs($x1,$x2)
                  a.txtfile($x5)
                  a.thread_count($x11.to_i)
                  a.tests
                end
              else
                a = Cidrportscanner.new
                a.range_addrs($x1,$x2)
                a.tests
              end
            elsif $x6 !=nil
              if $x11 !=nil || $x5 !=nil
                if $x7 !=nil
                  a = Cidrportscanner.new
                  a.cidr_range($x6)
                  a.thread_count($x11.to_i)
                  a.txtfile($x5)
                  a.change_uagent($x7)
                  a.tests
                else
                  a = Cidrportscanner.new
                  a.cidr_range($x6)
                  a.thread_count($x11.to_i)
                  a.txtfile($x5)
                  a.tests
                end
              else
                a = Cidrportscanner.new
                a.cidr_range($x6)
                a.tests
              end
            elsif $x9 !=nil
               if $x11 !=nil || $x5 !=nil
                if $x7 !=nil
                  a = Cidrportscanner.new
                  a.iprangefile($x9)
                  a.thread_count($x11.to_i)
                  a.txtfile($x5)
                  a.change_uagent($x7)
                  a.tests
                else
                  a = Cidrportscanner.new
                  a.iprangefile($x9)
                  a.thread_count($x11.to_i)
                  a.txtfile($x5)
                  a.tests
                end
              else
              a = Cidrportscanner.new
              a.iprangefile($x9)
              a.tests
              end
            elsif $x10 !=nil
              singip = $x10.split(/,/).to_a
              block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
              re = /\A#{block}\.#{block}\.#{block}\.#{block}\z/
              if singip.all? {|i| i.match(re) }
                xb11 = singip.each.map(&:to_s)
                if $x5 !=nil || $x11 !=nil
                  if $x7 !=nil
                    a2 = Cidrportscanner.new
                    a2.singleiphit(xb11)
                    a2.thread_count($x11.to_i)
                    a2.txtfile($x5)
                    a2.scantypes($x13)
                    a2.change_uagent($x7)
                    a2.tests
                  else
                    a2 = Cidrportscanner.new
                    a2.singleiphit(xb11)
                    a2.thread_count($x11.to_i)
                    a2.txtfile($x5)
                    a2.scantypes($x13)
                    a2.tests
                  end

                else
                  a2 = Cidrportscanner.new
                  a2.singleiphit(xb11)
                  a2.scantypes($x13)
                  a2.tests
                end
              else
                puts "\tWarning: ".red+"You have provided some wrong ip address"
              end

            else
              puts "\tWarning: ".red+"provide web port scan arguments"
           end
      end
  end

 #Screenshot and deep redirection check---------------------------------------------------------------------------------------

when 'redirect-scr'
  if $x1 != nil && $x2 != nil && $x6 !=nil
    puts "\tWarning: ".red+"Please provide either (-s 0.0.0.0 -e 0.0.0.0) range of ip addresses or (-r 0.0.0.0/24) cidr notation"
    puts
    puts "\tUsage: ruby #{$0} ".white + "[".green + "OPTIONS".white + "] ".green + " -h ".green + " or " + " --help".green
    puts
    exit
    else
        if $x1 != nil && $x2 != nil
            if $x11 !=nil || $x5 !=nil
                a = Deepredirection.new
                a.range_addrs($x1,$x2)
                a.txtfile($x5)
                a.thread_count($x11.to_i)
                a.checkredirector
            else  
              a = Deepredirection.new
              a.range_addrs($x1,$x2)
              a.checkredirector
            end
          elsif $x6 !=nil
            if $x11 !=nil || $x5 !=nil
                a = Deepredirection.new
                a.cidr_range($x6)
                a.thread_count($x11.to_i)
                a.txtfile($x5)
                a.checkredirector
            else
              a = Deepredirection.new
              a.cidr_range($x6)
              a.checkredirector
            end
          elsif $x9 !=nil
             if $x11 !=nil || $x5 !=nil
              a = Deepredirection.new
              a.iprangefile($x9)
              a.thread_count($x11.to_i)
              a.txtfile($x5)
              a.checkredirector
            else
            a = Deepredirection.new
            a.iprangefile($x9)
            a.checkredirector
            end
          else
            puts "provide range scan arguments"
         end
    end
# next module --------------------------------------------------------------------------------------------------------------
  when 'vhostfind'
    if $x4 !=nil
      if $x3 !=nil
        if $x11 !=nil || $x5 !=nil
          if $x7 !=nil
            aa = Vhfind1.new
            aa.domain_name($x4)
            aa.thread_count($x11.to_i)
            aa.fname($x3)
            aa.txtfile($x5)
            aa.change_uagent($x7)
            aa.vscan
          else
            aa = Vhfind1.new
            aa.domain_name($x4)
            aa.thread_count($x11.to_i)
            aa.fname($x3)
            aa.txtfile($x5)
            #aa.change_uagent("true")
            aa.vscan
          end
        else
          if $x7 !=nil
            aa = Vhfind1.new
            aa.domain_name($x4)
            aa.fname($x3)
            aa.change_uagent($x7)
            aa.vscan
          else
            aa = Vhfind1.new
            aa.fname($x3)
            aa.domain_name($x4)
            aa.vscan
          end
        end
#--------------------------------
      else
        if $x11 !=nil || $x5 !=nil
          if $x7 !=nil
            aa = Vhfind1.new
            aa.domain_name($x4)
            aa.thread_count($x11.to_i)
            #aa.fname($x3)
            aa.txtfile($x5)
            aa.change_uagent($x7)
            aa.vscan
          else
            aa = Vhfind1.new
            aa.domain_name($x4)
            aa.thread_count($x11.to_i)
            #aa.fname($x3)
            aa.txtfile($x5)
            #aa.change_uagent("true")
            aa.vscan
          end
        else
          if $x7 !=nil
            aa = Vhfind1.new
            aa.domain_name($x4)
            #aa.fname($x3)
            aa.change_uagent($x7)
            aa.vscan
          else
            aa = Vhfind1.new
            #aa.fname($x3)
            aa.domain_name($x4)
            aa.vscan
          end
        end
      end
    elsif $x9 !=nil
      #-------------------------------------
            if $x3 !=nil
              if $x11 !=nil || $x5 !=nil
                if $x7 !=nil
                  aa = Vhfind1.new
                  aa.main_domain_file_list($x9)
                  aa.thread_count($x11.to_i)
                  aa.fname($x3)
                  aa.txtfile($x5)
                  aa.change_uagent($x7)
                  aa.vscan
                else
                  aa = Vhfind1.new
                  aa.main_domain_file_list($x9)
                  aa.thread_count($x11.to_i)
                  aa.fname($x3)
                  aa.txtfile($x5)
                  #aa.change_uagent("true")
                  aa.vscan
                end
              else
                if $x7 !=nil
                  aa = Vhfind1.new
                  aa.main_domain_file_list($x9)
                  aa.fname($x3)
                  aa.change_uagent($x7)
                  aa.vscan
                else
                  aa = Vhfind1.new
                  aa.fname($x3)
                  aa.main_domain_file_list($x9)
                  aa.vscan
                end
              end
            else
              if $x11 !=nil || $x5 !=nil
                if $x7 !=nil
                  aa = Vhfind1.new
                  aa.main_domain_file_list($x9)
                  aa.thread_count($x11.to_i)
                  #aa.fname($x3)
                  aa.txtfile($x5)
                  aa.change_uagent($x7)
                  aa.vscan
                else
                  aa = Vhfind1.new
                  aa.main_domain_file_list($x9)
                  aa.thread_count($x11.to_i)
                  #aa.fname($x3)
                  aa.txtfile($x5)
                  #aa.change_uagent("true")
                  aa.vscan
                end
              else
                if $x7 !=nil
                  aa = Vhfind1.new
                  aa.main_domain_file_list($x9)
                  #aa.fname($x3)
                  aa.change_uagent($x7)
                  aa.vscan
                else
                  aa = Vhfind1.new
                  #aa.fname($x3)
                  aa.main_domain_file_list($x9)
                  aa.vscan
                end
              end
            end
    else
      puts "\tProvide valid args fors vhostfind\n"
    end
  when 'echotest'
    if $x8 !=nil
      aa = Cswh.new($x8)
      aa.test1
      aa.websocket
    end
  else
    puts "\tThe script or as doesn't exist\n"
    puts
    puts "\tUsage: ruby #{$0} ".white + "[".green + "OPTIONS".white + "] ".green + " -h ".green + " or " + " --help".green
    puts
    puts
  end
end
