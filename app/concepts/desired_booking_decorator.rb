# frozen_string_literal: true
class DesiredBookingDecorator
  DAYS_OF_WEEK = {
    "sunday" => 0,
    "monday" => 1,
    "tuesday" => 2,
    "wednesday" => 3,
    "thursday" => 4,
    "friday" => 5,
    "saturday" => 6
  }

  def self.next_datetime(desired_booking)
    current_date = Date.today

    # Convert the day of the week from a string to an integer
    desired_day_of_week = DAYS_OF_WEEK[desired_booking[:day_of_week].downcase]

    # Calculate the difference between the current day of the week and the desired day of the week
    day_difference = desired_day_of_week - current_date.wday

    # If the desired day has already passed this week, go to the next week
    day_difference += 7 if day_difference < 0

    desired_date = current_date + day_difference

    DateTime.new(desired_date.year, desired_date.month, desired_date.day, desired_booking[:hour])
  end
end
