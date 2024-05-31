# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  DEFAULT_FROM_NAME = 'Leti'
  DEFAULT_FROM_ADDRESS = 'no-reply@leti.com'
  default from: "#{DEFAULT_FROM_NAME} <#{DEFAULT_FROM_ADDRESS}>"

  private

  def mail(args = {})
    template_id = args[:template_id]
    body = args[:body]
    to = args[:to]

    unless ENV.fetch('SEND_EMAILS', 'true') == 'true'
      Rails.logger.info('[Emails] Skipping email because SEND_EMAILS is false')
      return
    end

    unless template_id.present? || body.present?
      Rails.logger.info('[Emails] Skipping email because template_id and body are not present')
      return
    end

    if Array(to).empty?
      Rails.logger.info('[Emails] Skipping email because no destination address')
      return
    end

    Rails.logger.info("[Emails] Sending #{self.class.name} email", to:, template_id:)

    super(args)
  end
end
