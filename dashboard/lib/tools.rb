#!/usr/bin/env ruby
# Registry of recon tools pluggable into scan engine pipelines. Each entry
# describes how to build a shell command for a target, how to check the
# tool is actually installed on the host it will run on, and how to turn
# its stdout lines into normalized findings.
require 'shellwords'
require_relative 'util'

module Tools
  # $RECO_HOME is set by the executor: local repo root when running on the
  # dashboard host itself, or the configured remote checkout path over SSH.
  RECO_CMD = 'cd "$RECO_HOME" && ruby reco.rb'

  DEFAULT_WORDLIST = 'wordlist/host_word_list.txt'

  SUBDOMAIN_RE = /\A[a-z0-9](?:[a-z0-9\-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9\-]{0,61}[a-z0-9])?)+\z/i

  # binary: the executable checked with `command -v` before a stage runs.
  #         :env_burp is special-cased (checks BURP_API_URL/KEY instead).
  TOOLS = {
    'reco_subenum' => {
      label: 'reco: Subdomain enumeration',
      binary: 'ruby',
      build: ->(t, o) { "#{RECO_CMD} --script subenum -d #{t.shellescape} --subtype #{(o['subtype'] || 'full').shellescape} --thread #{(o['threads'] || 20)} #{o['args']}" },
      parse: ->(line) {
        m = Util.strip_ansi(line).match(/Subdomain:\s*(\S+)\s+(\S+)\s+(\S+)\s+\[(\w+)\]/)
        m ? { kind: 'subdomain', value: m[1], raw: line } : nil
      }
    },
    'reco_dnsrecon' => {
      label: 'reco: DNS record recon',
      binary: 'ruby',
      build: ->(t, o) { "#{RECO_CMD} --script dnsrecon -d #{t.shellescape} #{o['args']}" },
      parse: ->(line) {
        clean = Util.strip_ansi(line)
        m = clean.match(/^\|\s*(A|AAAA|MX|NS|TXT|CNAME|SOA)\s*\|\s*(.+?)\s*\|$/)
        m ? { kind: 'dns', value: "#{m[1]} #{m[2]}", raw: line } : nil
      }
    },
    'reco_portscan' => {
      label: 'reco: Web portal port scan',
      binary: 'ruby',
      build: ->(t, o) { "#{RECO_CMD} --script portscan --ip #{t.shellescape} --scantype #{(o['scantype'] || 'top').shellescape} --thread #{(o['threads'] || 20)} #{o['args']}" },
      parse: ->(line) {
        m = Util.strip_ansi(line).match(/Web Portal:\s*(\S+):(\d+)/)
        m ? { kind: 'port', value: "#{m[1]}:#{m[2]}", raw: line } : nil
      }
    },
    'reco_vhostscan' => {
      label: 'reco: Vhost / subdomain bruteforce',
      binary: 'ruby',
      build: ->(t, o) { "#{RECO_CMD} --script vhostfind -d #{t.shellescape} --thread #{(o['threads'] || 20)} #{o['args']}" },
      parse: ->(line) {
        m = Util.strip_ansi(line).match(/Status code:\s*(\d+):\s*(\S+)/)
        m ? { kind: 'subdomain', value: m[2], raw: line } : nil
      }
    },
    'nmap' => {
      label: 'nmap port/service scan',
      binary: 'nmap',
      build: ->(t, o) { "nmap #{o['args'] || '-sV -T4 -p- --min-rate 1000'} #{t.shellescape}" },
      parse: ->(line) {
        m = line.match(/^(\d+)\/(tcp|udp)\s+open\s+(\S+)/)
        m ? { kind: 'port', value: "#{m[1]}/#{m[2]} open #{m[3]}", raw: line } : nil
      }
    },
    'amass' => {
      label: 'amass passive subdomain enum',
      binary: 'amass',
      build: ->(t, o) { "amass enum #{o['args'] || '-passive'} -d #{t.shellescape}" },
      parse: ->(line) {
        line = line.strip
        (line =~ SUBDOMAIN_RE) ? { kind: 'subdomain', value: line, raw: line } : nil
      }
    },
    'masscan' => {
      label: 'masscan fast port scan',
      binary: 'masscan',
      build: ->(t, o) { "masscan #{t.shellescape} #{o['args'] || '-p1-65535 --rate 1000'}" },
      parse: ->(line) {
        m = line.match(/Discovered open port (\d+)\/(\w+) on (\S+)/)
        m ? { kind: 'port', value: "#{m[3]}:#{m[1]}/#{m[2]}", raw: line } : nil
      }
    },
    'gobuster' => {
      label: 'gobuster directory bruteforce',
      binary: 'gobuster',
      build: ->(t, o) { "gobuster dir -u #{("http://" + t).shellescape} -w #{(o['wordlist'] || DEFAULT_WORDLIST).shellescape} -q #{o['args']}" },
      parse: ->(line) {
        m = line.match(/^(\/\S*)\s+\(Status:\s*(\d+)\)/)
        m ? { kind: 'directory', value: "#{m[1]} [#{m[2]}]", raw: line } : nil
      }
    },
    'dirsearch' => {
      label: 'dirsearch directory bruteforce',
      binary: 'dirsearch',
      build: ->(t, o) { "dirsearch -u #{("http://" + t).shellescape} -w #{(o['wordlist'] || DEFAULT_WORDLIST).shellescape} --format=plain #{o['args']}" },
      parse: ->(line) {
        m = line.match(/^\[\d\d:\d\d:\d\d\]\s+(\d{3}).*?\s(\/\S*)\s*$/)
        m ? { kind: 'directory', value: "#{m[2]} [#{m[1]}]", raw: line } : nil
      }
    },
    'sqlmap' => {
      label: 'sqlmap SQL injection probe',
      binary: 'sqlmap',
      build: ->(t, o) { "sqlmap -u #{("http://" + t).shellescape} --batch #{o['args'] || '--crawl=1 --level=1 --risk=1'}" },
      parse: ->(line) {
        (line =~ /is vulnerable/i) ? { kind: 'vulnerability', value: line.strip, raw: line } : nil
      }
    },
    'spiderfoot' => {
      label: 'SpiderFoot OSINT sweep',
      binary: 'sf.py',
      build: ->(t, o) { "python3 sf.py -s #{t.shellescape} -m #{(o['modules'] || 'sfp_dnsresolve,sfp_crtsh').shellescape} -q #{o['args']}" },
      parse: ->(line) {
        line.strip.empty? ? nil : { kind: 'osint', value: line.strip, raw: line }
      }
    },
    'burp' => {
      label: 'Burp Suite scan (requires Burp Pro/Enterprise REST API)',
      binary: :env_burp,
      build: ->(t, o) {
        url = "http://#{t}"
        %(curl -s -X POST "$BURP_API_URL/v0.1/scan" -H "Authorization: $BURP_API_KEY" -H "Content-Type: application/json" -d '{"urls":["#{url}"]}')
      },
      parse: ->(line) { line.strip.empty? ? nil : { kind: 'other', value: line.strip, raw: line } }
    },
    'subfinder' => {
      label: 'subfinder passive subdomain enum',
      binary: 'subfinder',
      build: ->(t, o) { "subfinder -d #{t.shellescape} -silent #{o['args']}" },
      parse: ->(line) {
        line = line.strip
        (line =~ SUBDOMAIN_RE) ? { kind: 'subdomain', value: line, raw: line } : nil
      }
    },
    'httpx' => {
      label: 'httpx live host probe',
      binary: 'httpx',
      build: ->(t, o) { "echo #{t.shellescape} | httpx -silent -status-code -title #{o['args']}" },
      parse: ->(line) {
        m = line.strip.match(/\A(\S+)(?:\s+\[(\d+)\])?(?:\s+\[([^\]]*)\])?/)
        return nil unless m && m[1]
        { kind: 'http', value: [m[1], (m[2] ? "[#{m[2]}]" : nil), (m[3] ? "[#{m[3]}]" : nil)].compact.join(' '), raw: line }
      }
    },
    'naabu' => {
      label: 'naabu fast port scan',
      binary: 'naabu',
      build: ->(t, o) { "naabu -host #{t.shellescape} -silent #{o['args']}" },
      parse: ->(line) {
        line = line.strip
        (line =~ /\A\S+:\d+\z/) ? { kind: 'port', value: line, raw: line } : nil
      }
    },
    'nuclei' => {
      label: 'nuclei vulnerability templates',
      binary: 'nuclei',
      build: ->(t, o) { "nuclei -u #{("http://" + t).shellescape} -silent #{o['args']}" },
      parse: ->(line) {
        m = line.match(/^\[([^\]]+)\]\s+\[([^\]]+)\]\s+\[([^\]]+)\]\s+(\S+)/)
        m ? { kind: 'vulnerability', value: "#{m[1]} (#{m[3]}) #{m[4]}", raw: line } : nil
      }
    },
    'ffuf' => {
      label: 'ffuf web fuzzer',
      binary: 'ffuf',
      build: ->(t, o) { "ffuf -u #{("http://" + t + "/FUZZ").shellescape} -w #{(o['wordlist'] || DEFAULT_WORDLIST).shellescape} #{o['args']}" },
      parse: ->(line) {
        m = line.match(/^(\S+)\s+\[Status:\s*(\d+)/)
        m ? { kind: 'directory', value: "/#{m[1]} [#{m[2]}]", raw: line } : nil
      }
    },
    'waybackurls' => {
      label: 'waybackurls historical URL discovery',
      binary: 'waybackurls',
      build: ->(t, o) { "echo #{t.shellescape} | waybackurls #{o['args']}" },
      parse: ->(line) {
        line = line.strip
        (line =~ /\Ahttps?:\/\//) ? { kind: 'url', value: line, raw: line } : nil
      }
    },
    'dalfox' => {
      label: 'dalfox XSS scanner',
      binary: 'dalfox',
      build: ->(t, o) { "dalfox url #{("http://" + t).shellescape} --silence #{o['args']}" },
      parse: ->(line) {
        (line =~ /\[(POC|VULN)\]/) ? { kind: 'vulnerability', value: line.strip, raw: line } : nil
      }
    },
    'theharvester' => {
      label: 'theHarvester OSINT (emails, hosts, names)',
      binary: 'theHarvester',
      build: ->(t, o) { "theHarvester -d #{t.shellescape} -b #{(o['sources'] || 'all').shellescape} #{o['args']}" },
      parse: ->(line) {
        line = line.strip
        return nil if line.empty?
        return { kind: 'osint', value: line, raw: line } if line =~ /\A[\w.+-]+@[\w-]+\.[\w.-]+\z/
        (line =~ SUBDOMAIN_RE) ? { kind: 'subdomain', value: line, raw: line } : nil
      }
    },
    'whois' => {
      label: 'whois registration lookup',
      binary: 'whois',
      build: ->(t, o) { "whois #{t.shellescape} #{o['args']}" },
      parse: ->(line) {
        m = line.match(/^(Registrar|Registrant Name|Registrant Organization|Creation Date|Registry Expiry Date|Updated Date|Name Server)\s*:\s*(.+)$/i)
        m ? { kind: 'whois', value: "#{m[1].strip}: #{m[2].strip}", raw: line } : nil
      }
    },
    'subzy' => {
      label: 'subzy subdomain takeover check',
      binary: 'subzy',
      build: ->(t, o) { "subzy run --target #{t.shellescape} #{o['args']}" },
      parse: ->(line) {
        (line =~ /VULNERABLE/i) ? { kind: 'takeover', value: line.strip, raw: line } : nil
      }
    },
    'wafw00f' => {
      label: 'wafw00f WAF fingerprinting',
      binary: 'wafw00f',
      build: ->(t, o) { "wafw00f #{("http://" + t).shellescape} #{o['args']}" },
      parse: ->(line) {
        (line =~ /is behind|WAF detected|No WAF detected/i) ? { kind: 'waf', value: line.strip, raw: line } : nil
      }
    }
  }.freeze

  def self.available?(key)
    TOOLS.key?(key)
  end

  def self.binary_for(key)
    TOOLS.dig(key, :binary)
  end

  def self.label_for(key)
    TOOLS.dig(key, :label) || key
  end

  def self.command_for(key, target, opts = {})
    entry = TOOLS.fetch(key)
    entry[:build].call(target, opts)
  end

  def self.parse_line(key, line)
    entry = TOOLS[key]
    return nil unless entry
    entry[:parse].call(line)
  rescue
    nil
  end
end
