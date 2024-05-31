# frozen_string_literal: true

# Provides a formatter with desired defaults.
#
# The default Ougai JSON formatter comes with a pre-configured set of default
# fields that are printend with every log.
# Here we provide a formatter that overrides the set of default fields to
# a set of fields that we care about.
# Base class in: https://github.com/tilfin/ougai/blob/main/lib/ougai/formatters/bunyan.rb
#
class CustomLogFormatter < Ougai::Formatters::Bunyan
  def _call(severity, time, progname, data)
    # The following is a hotfix for a bug that causes SystemStackError
    # when data includes a Sidekiq Rails reloader object:
    # https://github.com/sidekiq/sidekiq/issues/5920
    data_fixed = data.dup
    if data_fixed.is_a?(Hash)
      data_fixed.delete(:reloader)
      data_fixed.delete(:schedule_manager)
    end

    context = {
      prog_name: progname || @app_name,
      pid: $PROCESS_ID,
      severity_tag: severity,
      severity_level: to_level(severity),
      time_utc: time.utc.strftime('%Y-%m-%d %H:%M:%S')
    }

    # Append user context if available
    # Note. When app is just starting, the Current module might not be loaded yet:
    if defined?(Current)
      user = Current.user
      admin_user = Current.admin_user
    end

    context.merge!(user.to_log_hash) if user.present?
    context.merge!(admin_user.to_log_hash) if admin_user.present?

    dump(context.merge(data_fixed))
  rescue Exception => e
    dump(
      context.merge(
        message: "Failed to generate log message #{e.inspect}"
      )
    )
  end

  # Called by Ougai::Formatters::Bunyan. Default implementation modifies the
  # date into a user-provided format. Here we disallow users from
  # modifying the time for the sake of having a standard format across
  # services.
  def convert_time(data)
    # no-op
  end
end
