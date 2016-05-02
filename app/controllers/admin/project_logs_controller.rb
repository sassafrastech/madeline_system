class Admin::ProjectLogsController < Admin::AdminController
  def destroy
    @log = ProjectLog.find(params[:id])
    @step = ProjectStep.find(@log.project_step_id)
    @loan = Loan.find(@step.project_id)

    authorize @log
    authorize @step
    authorize @loan

    if @log.destroy
      redirect_to admin_loan_path(@loan, anchor: 'timeline'), notice: I18n.t(:notice_deleted)
    else
      redirect_to admin_loan_path(@loan, anchor: 'timeline')
    end
  end

  def show
    @log = ProjectLog.find(params[:id])
    @step = ProjectStep.find(@log.project_step_id)
    @loan = Loan.find(@step.project_id)

    authorize @log
    authorize @step
    authorize @loan

    redirect_to admin_loan_path(@loan)
  end
end