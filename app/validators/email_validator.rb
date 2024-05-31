# frozen_string_literal: true

class EmailValidator < ActiveModel::EachValidator
  EMAIL_REGEX = /\A(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))\z/

  def validate_each(record, attribute, value)
    return if value.blank?

    return if value =~ EMAIL_REGEX

    record.errors.add(attribute, (options[:message] || 'is not an email'))
  end
end
