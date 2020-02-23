class Admin::Accounting::TransactionsController < Admin::AdminController
  include TransactionControllable

  def index
    authorize :'accounting/transaction', :index?

    initialize_transactions_grid
  end

  def new
    @loan = Loan.find_by(id: params[:project_id])
    @transaction = Accounting::Transaction.new(project_id: params[:project_id], txn_date: Date.today)
    authorize @transaction, :new?

    prep_transaction_form
    render_modal_partial
  end

  def show
    @loan = Loan.find_by(id: params[:project_id])
    @transaction = ::Accounting::Transaction.find_by(id: params[:id])
    authorize @transaction, :show?

    prep_transaction_form
    render_modal_partial
  end

  def create
    @loan = Loan.find(transaction_params[:project_id])
    authorize(@loan, :update?)
    @transaction = ::Accounting::Transaction.new(transaction_params)
    unless respects_closed_books_date(@transaction)
      @transaction.errors.add(:txn_date, :closed_books_date)
      prep_transaction_form
      render_modal_partial(status: 422)
      return
    end
    @transaction.managed = true
    @transaction.currency_id = @loan.currency_id
    process_transaction_and_handle_errors

    # Since the txn has already been saved and/or validated before qb errors are added,
    # valid? may be true even if there are errors.
    if @transaction.errors.any?
      prep_transaction_form
      render_modal_partial(status: 422)
    else
      # The JS modal view will reload the index page if we return 200, so we set a flash message.
      flash[:notice] = t("admin.loans.transactions.create_success")
      head :ok
    end
  end

  private

  # the txn model must be able to save managed txns before
  # the closed books date that are imported from qb
  # but should error if user is trying to create
  # a txn before the qb date via the Madeline interface
  def respects_closed_books_date(txn)
    txn.project.closed_books_date.nil? || (txn.txn_date > txn.project.closed_books_date)
  end

  # Saves transaction record and runs updater.
  # Does nothing if transaction is invalid.
  # Handles any QB errors that come up in updater and sets them as base errors on @transaction.
  def process_transaction_and_handle_errors
    # This is a database transaction, not accounting!
    # We use it because we want to rollback transaction creation or updates if there are errors.
    ActiveRecord::Base.transaction do
      if @transaction.save
        if error = handle_qb_errors { run_updater(project: @transaction.project) }
          @transaction.errors.add(:base, error)
          raise ActiveRecord::Rollback
        end
      end
    end
  end

  def transaction_params
    params.require(:accounting_transaction).permit(:project_id, :account_id, :amount,
      :private_note, :accounting_account_id, :description, :txn_date, :loan_transaction_type_value, :accounting_customer_id)
  end

  def render_modal_partial(status: 200)
    render partial: "admin/accounting/transactions/modal_content", status: status
  end
end
