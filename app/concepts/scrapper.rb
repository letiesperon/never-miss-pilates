# frozen_string_literal: true

class Scrapper
  include AppService

  def initialize(booking_datetime)
    @booking_datetime = booking_datetime
  end

  def book
    # Code to book the desired date and time
  end

  private

  attr_reader :booking_datetime
end
