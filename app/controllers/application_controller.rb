# frozen_string_literal: true

class ApplicationController < ActionController::Base
  respond_to :json, :html

  before_action :set_admin_user_in_current

  def not_found
    @page_title = 'Not Found'
    render template: 'errors/not_found', status: :not_found
  end

  private

  def current_audited_user
    try(:current_admin_user)
  end

  def set_admin_user_in_current
    # Used for logging in custom logs and event tracking. See ougai custom logger.
    Current.admin_user = current_admin_user
  end

  rescue_from ActiveRecord::RecordNotFound do |_exception|
    not_found
  end

  rescue_from ActionView::Template::Error do |exception|
    raise exception unless exception.cause.is_a?(ActiveRecord::RecordNotFound)

    not_found
  end
end
