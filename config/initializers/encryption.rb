# frozen_string_literal: true

Encryption.config do |e|
  e.key = [ENV.fetch('ENCRYPTION_KEY', nil)].pack('H*')
  e.iv = ENV.fetch('ENCRYPTION_VECTOR', nil)
  e.cipher = ENV.fetch('ENCRYPTION_CIPHER', nil)
end
