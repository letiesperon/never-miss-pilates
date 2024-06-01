# frozen_string_literal: true

# Enqueues a job to process each desired booking:

class Enqueuer
  class Worker
    include Sidekiq::Worker

    def perform
      Enqueuer.new.enqueue!
    end
  end

  def initialize
    @desired_bookings = DesiredBooking.enabled.all
  end

  def enqueue!
    desired_bookings.each do |desired_booking|
      Processor::Worker.perform_async(desired_booking.id)
    end
  end

  private

  attr_reader :desired_bookings
end
