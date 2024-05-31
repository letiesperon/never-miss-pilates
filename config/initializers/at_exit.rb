# frozen_string_literal: true
# at_exit do
#   begin
#     puts 'Closing LaunchDarkly client...'
#     Rails.configuration.ld_client.close
#     puts 'Flushing Segment queues...'
#     Analytics.flush
#   rescue => e
#     puts "There was an #{e.to_s} while shutting down..."
#   ensure
#     puts 'Done!'
#   end
# end unless Rails.env.production?
