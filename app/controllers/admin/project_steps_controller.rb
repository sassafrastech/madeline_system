class Admin::ProjectStepsController < Admin::AdminController
  helper TimeLanguageHelper

  def destroy
    @step = ProjectStep.find(params[:id])
    authorize @step

    if @step.destroy
      display_timeline(@step, I18n.t(:notice_deleted))
    else
      display_timeline(@step)
    end
  end

  def new
    @loan = Loan.find(params[:loan_id])
    @step = ProjectStep.new(project: @loan)
    authorize @step
    render_step_partial(:form)
  end

  def show
    @step = ProjectStep.find(params[:id])
    authorize @step

    display_timeline(@step)
  end

  def update
    @step = ProjectStep.find(params[:id])
    authorize @step

    valid = @step.update_with_translations(project_step_params, translations_params(@step.permitted_locales))
    render_step_partial(valid ? :show : :form)
  end

  def duplicate
    step = ProjectStep.find(params[:id])
    authorize step
    @steps = step.duplication.perform(params[:duplication])
    render(layout: false)
  end

  def batch_destroy
    step_ids = params[:'step-ids']
    project_id, notice = batch_operation(step_ids) do |step|
      step.destroy
    end
    display_timeline(project_id, notice)
  end

  def adjust_dates
    step_ids = params[:'step-ids']
    time_direction = params[:time_direction]
    num_of_days = params[:num_of_days].to_i

    sign = case time_direction
       when 'forward'
         1
       when 'backward'
         -1
       else
         raise "adjust_dates - unexpected or missing time_direction: #{time_direction}"
     end
    days_adjustment = sign * num_of_days

    project_id, notice = batch_operation(step_ids) do |step|
      step.adjust_scheduled_date(days_adjustment)
    end
    display_timeline(project_id, notice)
  end

  def finalize
    step_ids = params[:'step-ids']
    project_id, notice = batch_operation(step_ids) do |step|
      step.finalize
    end
    display_timeline(project_id, notice)
  end

  private

  # Returns the two values in an array, the project id, and a 'notice' string needed to redisplay
  # the timeline.
  def batch_operation(step_ids)
    success_count = 0
    failure_count = 0
    project_id = nil
    raise_error = true
    step_ids.split(',').each do |step_id|
      begin
        step = ProjectStep.find(step_id)
        authorize step
        project_id ||= step.project_id

        # If the block returns false, this indicates no change and this record should be left out of
        # both success and failure counts.
        if yield(step)
          success_count += 1
        end
        raise_error = false
      rescue => e
        Rails.logger.error("project step: #{step_id} - batch operation error: #{e}")
        raise e if raise_error
        failure_count += 1
      end
    end

    if failure_count == 0
      notice = I18n.t(:notice_batch_updated, count: success_count)
    else
      notice = I18n.t(:notice_batch_updated_with_failures,
        count: success_count, failure_count: failure_count)
    end

    [project_id, notice]
  end

  def project_step_params
    params.require(:project_step).permit(:is_finalized, :scheduled_date, :completed_date, :step_type_value)
  end

  #todo: factor out into a concern as we implement other translatable forms
  def translations_params(locales)
    translation_params_list = locales.map { |l| %I(locale_#{l} details_#{l} summary_#{l}) }.flatten
    result = params.require(:project_step).permit(translation_params_list + [:deleted_locales])
    # note, the 'deleted_locales' param is JSON encoded because it was easier to treat as a single field at the form level
    result[:deleted_locales] = JSON.parse(result[:deleted_locales])
    result
  end

  def display_timeline(project_id, notice = nil)
    redirect_to admin_loan_path(project_id, anchor: 'timeline'), notice: notice
  end

  private

  def render_step_partial(mode)
    render partial: "/admin/project_steps/project_step", locals: {step: @step, mode: mode}
  end
end

