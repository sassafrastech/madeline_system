class Repayment < ActiveRecord::Base
  belongs_to :loan, :foreign_key => 'LoanID'

  delegate :division, :division=, to: :loan

  def paid; self.date_paid ? true : false; end

  def status
    if self.paid
      :paid
    elsif self.date_due < Date.today
      :overdue
    else
      :due
    end
  end

  def status_date
    if self.paid
      "#{I18n.t :paid} #{ApplicationController.helpers.ldate(self.date_paid, format: :long)}"
    else
      "#{I18n.t :due} #{ApplicationController.helpers.ldate(self.date_due, format: :long)}"
    end
  end

  def amount_formatted
    if self.date_paid
      amount = self.amount_paid
    else
      amount = self.amount_due
    end
    loan.ensure_currency.format_amount(amount)
  end
end
