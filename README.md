[![HitCount](http://hits.dwyl.com/{kunshdeep2812}/{reco}.svg)](http://hits.dwyl.com/{kunshdeep2812}/{reco})
# Reco... (version 0.0.1)  <a href="https://kunshdeep.com"><img src="https://user-images.githubusercontent.com/40362096/78559302-ca3dcd80-7831-11ea-91e4-7161c644d0ef.png" width=100px alt="Reco...|kunshdeep"></a>[![Build Status](https://travis-ci.org/kunshdeep2812/reco.svg?branch=master)](https://travis-ci.org/kunshdeep2812/reco) [![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/kunshdeep2812/reco/pulse) [![GitHub contributors](https://img.shields.io/github/contributors/kunshdeep2812/reco)](https://github.com/kunshdeep2812/reco/graphs/contributors)
A recon tool for pentester's with a simple command line.  [![GitHub followers](https://img.shields.io/github/followers/kunshdeep2812.svg?style=social&label=Follow&maxAge=2592000)](https://github.com/kunshdeep2812?tab=followers)   [![GitHub stars](https://img.shields.io/github/stars/kunshdeep2812/reco.svg?style=social&label=Star&maxAge=2592000)](https://github.com/kunshdeep2812/reco/stargazers)   [![GitHub watchers](https://img.shields.io/github/watchers/kunshdeep2812/reco.svg?style=social&label=Watch&maxAge=2592000)](https://github.com/kunshdeep2812/reco/watchers)
### Features:-
  > - Range scan of ip's
  > - Port scan on IP-range/Domain's
  > - Vhost finder
  > - Echo test of websocket to check cross site websocket hijacking
  > - Redirection url check
  > - Working domain Screenshot's
### Upcoming features:-
> - Subdomain finder, deep recon interface, some common exploits.
### Installation & Usage
```sh
git clone https://github.com/kunshdeep2812/reco.git
cd reco
sudo bash ./install.sh
ruby reco.rb --help/-h
```
##### Note:- 
If you are using the "rbenv" then run the ```install.sh``` file without ```sudo``` or perform the installation task manually of each command in ```install.sh```.

### Options
```ruby
Usage: ruby reco.rb --script [OPTIONS] ..[OPTIONS]

How to use: reco.rb --script rangescan -s 192.0.0.1 -e 192.0.0.255 --thread 10
How to use: reco.rb --script portscan --ip 192.168.0.6 --scantype custom -p 80,443,23 --thread 40
How to use: reco.rb --script rangescan -r 192.168.0.1/24 -o test.csv --thread 10
How to use: reco.rb --script portscan --iL /home/test/example.txt --randomagent true --thread 50 -o example.txt
How to use: reco.rb --script echotest --socketurl wss://example.com
How to use: reco.rb --help

For more please check the commands.txt file

Options: 
    -s, --startIPAddress             Provide Starting IPaddress
                                                                                                                                                                      
    -e, --endIPAddress               Provide ending IPaddress
                                                                                                                                                                      
    -o, --output                     Provide filename with extension(.txt)
                                                                                                                                                                      
    -w, --wordlist                   Provide filename which contains wordlist
                                                                                                                                                                      
    -d, --domain                     Provide domain name for bruteforce subdomain
                                                                                                                                                                      
    -r, --ipRange                    Provide IpAddress Range (e.g.: 192.0.168.1/24)
                                                                                                                                                                      
        --randomagent                For random user-agent, set --randomagent true
                                                                                                                                                                      
        --socketurl                  Provide socket initiation url
                                                                                                                                                                      
        --iL                         provide the list of ipaddress/domain-name file
                                                                                                                                                                      
        --ip                         provide single Ip
                                                                                                                                                                      
        --thread                     provide number of threads
                                                                                                                                                                      
        --script                     provide specific script name
                                                                                                                                                                      
        --scantype                   provide port scan type (full, top, custom)
                                                                                                                                                                      
    -p, --port                       Provide single or multiple port to scan
                                                                                                                                                                      
    -h, --help                       Help Menu
                                                                                                                                                                      
        --scriptlist                 List of scripts or modules

```
### Operating Systems supported
> - Linux (recommended)
> - Windows
###### Note:- 
This tool work in kali(2020.1) perfectly! no lengthy process for installation, just run ```sudo bash ./install.sh ```.
If you are useing ```Non-GUI``` version of linux install web ```chromedriver``` manually to run ```selenium```--> https://chromedriver.chromium.org/.

### Screenshots:-

- Portscan
![portscan2](https://user-images.githubusercontent.com/40362096/78561734-de83c980-7835-11ea-91bc-10ea6554d671.png)

- Redirection checker and screenshots
![deep-redirec-screenshot](https://user-images.githubusercontent.com/40362096/78561985-3fab9d00-7836-11ea-8046-55d6ccfe415e.png)

- Vhost finder
![vhostfind](https://user-images.githubusercontent.com/40362096/78562330-cbbdc480-7836-11ea-8f5b-15863553eb90.png)

# License
See the LICENSE file.
