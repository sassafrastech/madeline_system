class Admin::AdminController < ApplicationController
  include DivisionSelectable
  include Documentable

  layout 'admin/signed_in'

  helper_method :selected_division_id, :selected_division, :current_division

  prepend_before_action :authenticate_user!
  after_action :verify_authorized

  helper_method :current_user

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def admin_controller?
    true
  end

  def user_not_authorized
    if request.xhr?
      render nothing: true, status: 403
    else
      flash[:error] = t('unauthorized_error')
      redirect_to(request.referrer || root_path)
    end
  end
end
