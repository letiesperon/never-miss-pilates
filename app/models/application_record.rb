# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def to_log_hash
    {
      "#{log_prefix}_id": id
    }
  end

  def self.ransackable_attributes(...)
    authorizable_ransackable_attributes
  end

  def self.ransackable_associations(...)
    authorizable_ransackable_associations
  end

  private

  def log_prefix
    self.class.name.demodulize.underscore.gsub('/', '_')
  end
end
