require_relative 'test_helper'
require 'crypto'

class CryptoTest < Minitest::Test
  def test_roundtrip
    plaintext = 'correct horse battery staple'
    encrypted = Crypto.encrypt(plaintext)
    refute_equal plaintext, encrypted
    assert_equal plaintext, Crypto.decrypt(encrypted)
  end

  def test_nil_and_empty_input
    assert_nil Crypto.encrypt(nil)
    assert_nil Crypto.encrypt('')
    assert_nil Crypto.decrypt(nil)
    assert_nil Crypto.decrypt('')
  end

  def test_decrypt_garbage_returns_nil_not_raise
    assert_nil Crypto.decrypt('not-valid-base64-ciphertext!!!')
  end

  def test_each_encryption_uses_a_fresh_iv
    a = Crypto.encrypt('same input')
    b = Crypto.encrypt('same input')
    refute_equal a, b, 'ciphertext should differ each call due to a random IV'
  end
end
