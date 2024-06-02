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
  }

  def self.next_datetime(desired_booking)
    current_date = Time.now.in_time_zone('Montevideo').to_date
    desired_day_of_week = DAYS_OF_WEEK[desired_booking.day_of_week.downcase]
    desired_time = desired_booking.hour
    day_difference = desired_day_of_week - current_date.wday
    day_difference += 7 if day_difference < 0
    desired_date = current_date + day_difference
    datetime = desired_date.in_time_zone('Montevideo').change(hour: desired_time)
    datetime += 7.days if datetime.past?

    BookingDatetime.new(datetime:)
  end
end
