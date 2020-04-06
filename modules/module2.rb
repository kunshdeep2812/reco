#module Cross-site WebSocket hijacking
require 'faye/websocket'
require 'eventmachine'
require 'json'
require 'colorize'

class Paramss
  def test1
        puts "Press control + c to exit".green
        puts
        puts "Enter the web socket message:"
        puts
        @@dlr = STDIN.gets.chomp.to_s
	end
end

class Cswh < Paramss

    def initialize(url)
        @url = url
      end

      def websocket
        $url1 = @url
        $msg = @@dlr
        begin
            EM.run { 
                ws = Faye::WebSocket::Client.new("#{$url1}", [],{
                  :headers    => { 'Origin' => 'null',
                                   'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:68.0) Gecko/20100101 Firefox/68.0',
                                   'Connection' => 'Upgrade',
                                   'Upgrade' => 'websocket',
                                   'Sec-WebSocket-Key' => 'W9CI5otJev0BR/n4EB3C2Q=='}
              }
                )
                puts "\n\t\tThe Cross-site WebSocket hijacking vulnerability\n".green+"\tis only valuable when you are able to retrive some sensitive data\n"+"\t\t from web server in response sensitive message\n"

                ws.onopen = lambda do |event|
                  puts ["\n\t\t[Socket Open]".red]
                  ar = ws.url
                  tt = ws.headers
                  aa = tt.to_h
                  puts(
'
Connection initated:---  ---.
                       ||
                       \/  

'
                  )
                  puts "\t\tSocket URL: ".yellow+"#{ar}"
                  aa.each do |v, t|
                      puts "\t\t#{v}: ".green+"#{t}"
                  end
                  puts
                  puts ["\n   Your Message: "+"#{$msg}"]
                  ws.send("#{$msg}")
                end
                ws.onclose = lambda do |close|
                  #puts ["  Connection Close: ".green+"#{close.reason||"Nil"}"] #:close, close.code, close.reason]
                  EM.stop
                end
                ws.onerror = lambda do |error|
                  puts
                  puts ["  Error: ".green+"#{error.message}"]
                  puts
                end
              
                ws.onmessage = lambda do |message|
                 puts ["   Server Response: ".green+"#{message.data}"]
                 puts
                 EM.stop
                end
              }
          rescue => e
            puts e
          end
      end
end
