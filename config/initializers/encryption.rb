# frozen_string_literal: true

Encryption.config do |e|
  e.key = [ENV['ENCRYPTION_KEY']].pack('H*')
  e.iv = ENV['ENCRYPTION_VECTOR']
  e.cipher = ENV['ENCRYPTION_CIPHER']
end
