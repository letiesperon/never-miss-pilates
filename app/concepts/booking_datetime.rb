# frozen_string_literal: true

class BookingDatetime
  attr_reader :date, :time, :datetime

  def initialize(datetime:)
    @datetime = datetime
    @date = datetime.to_date
    @time = datetime.strftime('%H:%M')
  end

  def date_s
    date.strftime('%Y-%m-%-d') # EG: 2024-06-8
  end
end
