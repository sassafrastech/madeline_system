# frozen_string_literal: true

module Accounting
  module QB
    # Extract Deposit format quickbook transactions
    class DepositExtractor < TransactionExtractor
      attr_accessor :line_items
      delegate :qb_division, to: :loan

      def set_type
        txn.loan_transaction_type_value = 'repayment'
      end

      def extract_account
        qb_id = txn.quickbooks_data["deposit_to_account_ref"]["value"]
        txn.account = Accounting::Account.find_by(qb_id: qb_id)
        ::Accounting::ProblemLoanTransaction.create(loan: @loan, accounting_transaction: txn, message: :unprocessable_account, level: :error, custom_data: {}) if txn.account.nil?
      end

      # Using total assumes that all line items in txn are for accts in Madeline.
      # This assumption is safe because we never push amount to QB.
      def calculate_amount
        txn.amount = txn.total
      end

      def add_implicit_line_items
        txn.line_items << LineItem.new(
          account: txn.account,
          amount: txn.amount,
          posting_type: 'Debit'
        )
      end

      def existing_li_posting_type
        "Credit"
      end

      def qb_li_detail_key
        'deposit_line_detail'
      end
    end
  end
end
