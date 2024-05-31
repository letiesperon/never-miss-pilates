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

  # Overrides the default ActiveRecord `with_lock` to ALSO use the `Lockable` definition.
  # This is necessary because the default `with_lock` and the `Lockable` one use
  # different locking mechanisms. Without this change, if one part of the application uses
  # ActiveRecord's `with_lock` and another part uses the one from the `Lockable`
  # module, their blocks might be executed in parallel, leading to potential
  # concurrency issues.
  def with_lock(&)
    with_lock_no_transaction(self) do
      super(&)
    end
  end

  private

  def log_prefix
    self.class.name.demodulize.underscore.gsub('/', '_')
  end
end
