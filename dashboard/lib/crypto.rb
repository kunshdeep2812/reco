#!/usr/bin/env ruby
# Symmetric encryption for at-rest secrets (SSH passwords). SSH key-based auth
# never touches this — only used when a host is configured with password auth.
require 'openssl'
require 'base64'
require 'fileutils'

module Crypto
  SECRET_FILE = File.expand_path('../data/secret.key', __dir__)

  def self.key
    return @key if @key
    if ENV['RECO_SECRET_KEY'] && !ENV['RECO_SECRET_KEY'].empty?
      @key = OpenSSL::Digest::SHA256.digest(ENV['RECO_SECRET_KEY'])
    else
      FileUtils.mkdir_p(File.dirname(SECRET_FILE))
      unless File.exist?(SECRET_FILE)
        File.write(SECRET_FILE, OpenSSL::Random.random_bytes(32))
        File.chmod(0600, SECRET_FILE)
      end
      @key = File.binread(SECRET_FILE)
    end
    @key
  end

  def self.encrypt(plaintext)
    return nil if plaintext.nil? || plaintext.empty?
    cipher = OpenSSL::Cipher.new('aes-256-gcm')
    cipher.encrypt
    cipher.key = key
    iv = cipher.random_iv
    ciphertext = cipher.update(plaintext) + cipher.final
    tag = cipher.auth_tag
    Base64.strict_encode64(iv + tag + ciphertext)
  end

  def self.decrypt(blob)
    return nil if blob.nil? || blob.empty?
    raw = Base64.strict_decode64(blob)
    iv = raw[0, 12]
    tag = raw[12, 16]
    ciphertext = raw[28..]
    cipher = OpenSSL::Cipher.new('aes-256-gcm')
    cipher.decrypt
    cipher.key = key
    cipher.iv = iv
    cipher.auth_tag = tag
    cipher.update(ciphertext) + cipher.final
  rescue
    nil
  end
end
