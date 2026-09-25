#!/usr/bin/env ruby
module Util
  ANSI_RE = /\e\[[0-9;]*m/

  def self.strip_ansi(str)
    str.to_s.gsub(ANSI_RE, '')
  end
end
