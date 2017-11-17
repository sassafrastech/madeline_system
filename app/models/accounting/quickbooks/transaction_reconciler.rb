# Responsible for updating or creating transaction entries in Quickbooks.
module Accounting
  module Quickbooks
    class TransactionReconciler
      def initialize(qb_division = Division.root)
        @qb_division = qb_division
        @qb_connection = qb_division.qb_connection
        @principal_account = qb_division.principal_account
      end

      # Creates or updates a transaction in QB based on a Transaction object created in Madeline.
      def reconcile(transaction)
        return unless transaction.needs_qb_push?

        je = builder.build_for_qb(transaction)

        # If the transaction already has a qb_id then it already exists in QB, so we should update it.
        # Otherwise we create it.
        je = transaction.qb_id ? service.update(je, sparse: true) : service.create(je)

        transaction.set_qb_push_flag!(false)

        # It's important we store the ID and type of the QB journal entry we just created
        # so that on the next sync, a duplicate is not created.
        transaction.associate_with_qb_obj(je)
      end

      private

      attr_reader :qb_connection, :principal_account, :qb_division

      def builder
        @builder ||= TransactionBuilder.new(qb_division)
      end

      def service
        @service ||= ::Quickbooks::Service::JournalEntry.new(qb_connection.auth_details)
      end
    end
  end
end
