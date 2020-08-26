# frozen_string_literal: true

module Accounting
  module QB
    # Extract Purchase format quickbook transactions
    class PurchaseExtractor < TransactionExtractor
      attr_accessor :line_items
      delegate :qb_division, to: :loan

      def set_type
        txn.loan_transaction_type_value = 'disbursement'
      end

      def extract_account
        qb_id = txn.quickbooks_data["account_ref"]["value"]
        txn.account = Accounting::Account.find_by(qb_id: qb_id)
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
          posting_type: 'Credit'
        )
      end

      def existing_li_posting_type
        "Debit"
      end

      def qb_li_detail_key
        "account_based_expense_line_detail"
      end
    end
  end
end