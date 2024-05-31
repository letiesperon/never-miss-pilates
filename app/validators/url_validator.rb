# frozen_string_literal: true

class UrlValidator < ActiveModel::EachValidator
  URL_REGEX = %r{\A((https?)://)?(www.)?\S{2,256}\.[a-z]{1,}\b(/\S+/?)*\z}

  def validate_each(record, attribute, value)
    return if value.blank?

    return if value =~ URL_REGEX

    record.errors.add(attribute, (options[:message] || 'is not a valid URL'))
  end
end
