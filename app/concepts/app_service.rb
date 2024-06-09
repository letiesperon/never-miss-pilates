# frozen_string_literal: true

module AppService
  class Messages
    include Enumerable

    def initialize
      @messages = {}
    end

    def add(attribute, message)
      messages[attribute] = if messages[attribute].present?
                              [messages[attribute], message].flatten.uniq
                            else
                              message
                            end
    end

    def full_messages
      messages.map { |attribute, message|
        attr_text = "#{attribute}: " unless attribute == :base

        "#{attr_text}#{message}"
      }.join(', ')
    end

    delegate :blank?, :present?, :==, :[], :include?, :inspect, :each, :to_h, :to_hash, :empty?,
             :to_json, :as_json, to: :messages

    private

    attr_reader :messages
  end

  def success?
    errors.blank?
  end

  def errors
    @errors ||= Messages.new
  end

  def failure?
    !success?
  end

  def add_error(attribute, error)
    errors.add(attribute, error)
  end

  def persist(*models)
    persister = Persister.new(models)
    persister.persist
    add_errors(persister.errors) if persister.failure?
  end

  def persist!(*models)
    persister = Persister.new(models)
    persister.persist!
  end

  def add_errors(errors, root_key: nil)
    errors.each do |error|
      if error.respond_to?(:attribute)
        attribute = error.attribute
        message = error.message
      elsif error.is_a?(Array)
        attribute = error[0]
        message = error[1]
      elsif error.is_a?(String)
        attribute = :base
        message = error
      end

      if root_key.present?
        add_error(root_key, { attribute => message })
      else
        add_error(attribute, message)
      end
    end
  end

  def raise_errors
    return unless failure?

    raise StandardError, errors.full_messages
  end

  def rollback_if_errors
    return unless failure?

    raise ActiveRecord::Rollback, errors.full_messages
  end

  def clear_errors
    @errors = nil
  end

  def with_transaction(&)
    ActiveRecord::Base.transaction(&)
  end
end
