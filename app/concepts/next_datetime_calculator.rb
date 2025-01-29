# frozen_string_literal: true

class NextDatetimeCalculator
  DAYS_OF_WEEK = {
    'sunday' => 0,
    'monday' => 1,
    'tuesday' => 2,
    'wednesday' => 3,
    'thursday' => 4,
    'friday' => 5,
    'saturday' => 6
  }.freeze

  def self.next_datetime(desired_booking)
    current_date = Time.now.in_time_zone('Montevideo').to_date

    desired_day_of_week = DAYS_OF_WEEK[desired_booking.day_of_week.downcase]
    day_difference = desired_day_of_week - current_date.wday
    day_difference += 7 if day_difference.negative?

    desired_date = current_date + day_difference

    desired_hour = desired_booking.time.hour
    desired_minute = desired_booking.time.min

    datetime = desired_date.in_time_zone('Montevideo')
                           .change(hour: desired_hour, min: desired_minute)

    datetime += 7.days if datetime.past?

    BookingDatetime.new(datetime:)
  end
end
