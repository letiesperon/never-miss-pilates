# frozen_string_literal: true

class ErrorHandling
  def self.notify(e, metadata = {})
    humanized = "#{e.class}: #{e.message}"
    Rails.logger.error(humanized, error: humanized, backtrace: e.backtrace&.join("\n"))

    Bugsnag.notify(e) do |event|
      event.add_metadata(:diagnostics, metadata)
    end

    e.define_singleton_method(:skip_bugsnag) do
      true
    end
  end

  def self.warn(message, metadata = {})
    Bugsnag.notify(message) do |event|
      event.severity = 'warning'
      event.add_metadata(:diagnostics, metadata)
    end
  end
end
