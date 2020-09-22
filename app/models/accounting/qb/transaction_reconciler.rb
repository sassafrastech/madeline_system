# Responsible for updating or creating transaction entries in Quickbooks.
module Accounting
  module QB
    class TransactionReconciler
      def initialize(qb_division = Division.root)
        @qb_division = qb_division
        @qb_connection = qb_division.qb_connection
        @principal_account = qb_division.principal_account
      end

      # Creates or updates a transaction in QB based on a Transaction object created in Madeline.
      def reconcile(transaction)
        Rails::Debug.logger.ap("RECONCILING . . . ")
        Rails::Debug.logger.ap(transaction)
        return unless transaction.needs_qb_push?
        if transaction.qb_id.present?
          current_qb_je = service(transaction).find_by(:id, transaction.qb_id).first
          Rails::Debug.logger.ap("doc num from qb: #{current_qb_je.doc_number}")
        end

        qb_txn = builder.build_for_qb(transaction)
        Rails::Debug.logger.ap("doc num from builder: #{qb_txn.doc_number}")

        # If the transaction already has a qb_id then it already exists in QB, so we should update it.
        # Otherwise we create it.
        raise StandardError, "DO NOT WRITE IN READ ONLY MODE" if @qb_division.qb_read_only
        qb_txn = transaction.qb_id ? service(transaction).update(qb_txn, sparse: true) : service(transaction).create(qb_txn)
        Rails::Debug.logger.ap("doc num after qb update: #{qb_txn.doc_number}")

        transaction.set_qb_push_flag!(false)

        # It's important we store the ID and type of the QB journal entry we just created
        # so that on the next sync, a duplicate is not created.
        transaction.associate_with_qb_obj(qb_txn)
        transaction.save!
      end

      private

      attr_reader :qb_connection, :principal_account, :qb_division

      def builder
        @builder ||= TransactionBuilder.new(qb_division)
      end

      def service(m_txn)
        m_txn.subtype?("Check") ? purchase_service : je_service
      end

      def purchase_service
        @purchase_service ||= ::Quickbooks::Service::Purchase.new(qb_connection.auth_details)
      end

      def je_service
        @je_service ||= ::Quickbooks::Service::JournalEntry.new(qb_connection.auth_details)
      end
    end
  end
end
