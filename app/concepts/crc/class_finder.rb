# frozen_string_literal: true

module CRC
  class ClassFinder
    class ClassNotFoundError < ErrorWithMetadata; end
    class InvalidResponseError < ErrorWithMetadata; end

    def initialize(datetime:)
      @datetime = datetime
      @cycling_class = nil
    end

    def find!
      fetch_classes
      search_class_in_response
      validate_class_exists!
    end

    def class_id
      cycling_class&.fetch('id')
    end

    private

    attr_reader :datetime, :cycling_class, :response

    def fetch_classes
      search_request = CRC::SearchRequest.new(date: datetime.to_date)
      search_request.make_request

      @response = search_request.response_body
    end

    def search_class_in_response
      @cycling_class = response.find do |class_entry|
        class_name = class_entry.fetch('name')
        class_name_matches = class_name.downcase.include?('cycle')

        class_start_date_raw = class_entry.fetch('startDate')
        class_start_time = parse_time(class_start_date_raw)
        class_start_time_to_i = class_start_time.to_i
        datetime_to_i = datetime.to_i
        class_time_matches = class_start_time_to_i == datetime_to_i

        matches = class_name_matches && class_time_matches

        class_info = {
          datetime:,
          class_name_matches:,
          class_time_matches:,
          class_name:,
          class_start_date_raw:,
          class_start_time:,
          class_start_time_to_i:,
          datetime_to_i:
        }

        if matches
          Bugsnag.leave_breadcrumb('Class matched', class_info)
        else
          Bugsnag.leave_breadcrumb('Class NOT matched', class_info)
        end

        matches
      rescue KeyError => e
        raise InvalidResponseError.new('Unexpected response format',
                                       debugging_hash.merge(exception: e))
      end
    end

    def parse_time(datetime_s)
      # Has to assume the given datetime string is in Montevideo timezone,
      # even if it lacks the timezone information.
      # parse_time("2025-01-29T19:00:00") => Wed, 29 Jan 2025 19:00:00.000000000 -03 -03:00

      ActiveSupport::TimeZone['America/Montevideo'].parse(datetime_s)
    end

    def validate_class_exists!
      return if cycling_class

      raise ClassNotFoundError.new('No cycling class found', debugging_hash)
    end

    def debugging_hash
      { datetime:, response: }
    end
  end
end
