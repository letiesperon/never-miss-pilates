# frozen_string_literal: true

class ErrorWithMetadata < StandardError
  attr_reader :metadata

  def initialize(message, metadata)
    super(message)
    @metadata = metadata
  end

  def bugsnag_meta_data
    { tabname: metadata }
  end
end
