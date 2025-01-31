# frozen_string_literal: true

class BookingNotifier
  class Worker
    include Sidekiq::Worker

    sidekiq_options queue: :high, retry: false

    def perform(booking_id)
      booking = Booking.find(booking_id)
      BookingNotifier.new(booking:).notify!
    end
  end

  include AppService

  WHATSAPP_ACCOUNT_ID = ENV.fetch('WHATSAPP_ACCOUNT_ID', nil)
  WHATSAPP_ACCESS_TOKEN = ENV.fetch('WHATSAPP_ACCESS_TOKEN', nil)
  WHATSAPP_TEMPLATE_NAME = ENV.fetch('WHATSAPP_TEMPLATE_NAME', 'booking_confirmation')

  def initialize(booking:)
    @booking = booking
  end

  def notify!
    return unless can_send?

    send_whatsapp_message
    log_success
  end

  private

  attr_reader :booking

  delegate :admin_user, to: :booking
  delegate :phone_number, to: :admin_user

  def can_send?
    phone_number.present? && WHATSAPP_ACCOUNT_ID.present? && WHATSAPP_ACCESS_TOKEN.present?
  end

  def send_whatsapp_message
    HTTParty.post(
      "https://graph.facebook.com/v21.0/#{WHATSAPP_ACCOUNT_ID}/messages",
      headers: {
        'Authorization' => "Bearer #{WHATSAPP_ACCESS_TOKEN}",
        'Content-Type' => 'application/json'
      },
      body: {
        messaging_product: 'whatsapp',
        to: phone_number,
        type: 'template',
        template: {
          name: WHATSAPP_TEMPLATE_NAME,
          language: {
            code: 'en_US'
          }
        }
      }.to_json
    )
  end

  def log_success
    Rails.logger.info("[BookingNotifier] Notified #{phone_number}")
  end
end
