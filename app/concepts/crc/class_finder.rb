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
        class_start_time = parse_hour(class_start_date_raw)
        class_start_time_to_i = class_start_time.to_i
        datetime_to_i = datetime.to_i
        class_time_matches = class_start_time_to_i == datetime_to_i

        matches = class_name_matches && class_time_matches

        unless matches
          Bugsnag.leave_breadcrumb(
            'Class not matched',
            datetime:,
            class_name_matches:,
            class_time_matches:,
            class_name:,
            class_start_date_raw:,
            class_start_time:,
            class_start_time_to_i:,
            datetime_to_i:
          )
        end

        matches
      rescue KeyError => e
        raise InvalidResponseError.new('Unexpected response format',
                                       debugging_hash.merge(exception: e))
      end
    end

    def parse_hour(datetime)
      Time.parse(datetime)
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
