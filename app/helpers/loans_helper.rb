module LoansHelper
  def back_to_loans
    session[:loans_path] || loans_path
  end

  def health_status_icon(loan)
    if loan.loan_health_check.healthy?
      sanitize "<i class='fa fa-check-circle ms-tooltip' data-ms-title=#{health_status_message(loan)}></i> ", tags: %w(i), attributes: %w(class data-ms-title)
    else
      sanitize "<i class='fa fa-exclamation-triangle ms-tooltip' data-ms-title=#{health_status_message(loan)}></i> ", tags: %w(i), attributes: %w(class data-ms-title)
    end
  end

  def health_status_message(loan)
    if loan.loan_health_check.healthy?
      I18n.t("health_status.healthy")
    else
      "Unhealthy"
    end
  end
end
