require_relative 'test_helper'
require 'tools'

class ToolsTest < Minitest::Test
  def test_all_registered_tools_build_a_command_and_have_a_binary
    Tools::TOOLS.each_key do |key|
      cmd = Tools.command_for(key, 'example.com', {})
      assert_kind_of String, cmd
      refute_empty cmd
      assert Tools.available?(key)
      refute_nil Tools.binary_for(key)
    end
  end

  def test_command_shellescapes_the_target
    cmd = Tools.command_for('nmap', 'example.com; rm -rf /', {})
    refute_match(/; rm -rf/, cmd)
  end

  def test_reco_subenum_command_includes_subtype_and_domain
    cmd = Tools.command_for('reco_subenum', 'example.com', { 'subtype' => 'passive' })
    assert_match(/--script subenum/, cmd)
    assert_match(/-d example\.com/, cmd)
    assert_match(/--subtype passive/, cmd)
  end

  def test_parse_line_extracts_expected_finding_kinds
    cases = {
      'nmap'    => ['80/tcp open  http', 'port'],
      'naabu'   => ['example.com:443', 'port'],
      'waybackurls' => ['https://example.com/old', 'url'],
      'whois'   => ['Registrar: Example Inc.', 'whois'],
      'subzy'   => ['sub.example.com [VULNERABLE]', 'takeover'],
      'wafw00f' => ['example.com is behind Cloudflare WAF.', 'waf']
    }
    cases.each do |tool, (line, expected_kind)|
      finding = Tools.parse_line(tool, line)
      refute_nil finding, "expected #{tool} to parse a finding from: #{line.inspect}"
      assert_equal expected_kind, finding[:kind]
    end
  end

  def test_parse_line_returns_nil_for_noise
    assert_nil Tools.parse_line('nmap', 'Starting Nmap 7.94 at 2026-01-01')
    assert_nil Tools.parse_line('unknown_tool_key', 'anything')
  end

  def test_parse_line_never_raises_on_garbage_input
    Tools::TOOLS.each_key do |key|
      Tools.parse_line(key, "\xFF\xFE not valid utf8")
      Tools.parse_line(key, '')
    end
  end
end
