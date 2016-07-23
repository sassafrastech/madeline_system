class Admin::LoansController < Admin::AdminController
  include TranslationSaveable

  def index
    # Note, current_division is used when creating new entities and is guaranteed to return a value.
    # selected_division is used for index filtering, and may be unassigned.
    authorize Loan
    @loans_grid = initialize_grid(
      policy_scope(Loan),
      include: [:division, :organization, :currency, :primary_agent, :secondary_agent, :representative],
      conditions: division_index_filter,
      order: 'loans.signing_date',
      order_direction: 'desc',
      custom_order: {
        "divisions.name" => "LOWER(divisions.name)",
        "organizations.name" => "LOWER(organizations.name)",
        'loans.signing_date' => 'loans.signing_date IS NULL, loans.signing_date'
      },
      per_page: 50,
      name: 'loans',
      enable_export_to_csv: true
    )

    @csv_mode = true

    export_grid_if_requested do
      # This block only executes if CSV is not being returned
      @csv_mode = false
    end
  end

  def show
    @loan = Loan.find(params[:id])
    authorize @loan
    prep_form_vars
    @form_action_url = admin_loan_path
    @steps = @loan.project_steps
    @calendar_events_url = "/admin/calendar_events?loan_id=#{@loan.id}"
  end

  def new
    @loan = Loan.new(division: current_division)
    @loan.organization_id = params[:organization_id] if params[:organization_id]
    authorize @loan
    prep_form_vars
  end

  def steps
    @loan = Loan.find(params[:id])
    authorize @loan, :show?
    render layout: false
  end

  def questionnaires
    @loan = Loan.find(params[:id])
    authorize @loan, :show?

    # Value sets are sets of answers to criteria and post analysis question sets.
    @value_sets = ActiveSupport::OrderedHash.new
    @questions_json = {}

    Loan::QUESTION_SET_TYPES.each do |attrib|
      # Attempt to retrieve existing value set from object
      @value_sets[attrib] = @loan.send(attrib)

      # If existing set not found, build a blank one with which to render the form.
      unless @value_sets[attrib]
        @value_sets[attrib] = CustomValueSet.new(
          custom_value_set_linkable: @loan,
          custom_field_set: CustomFieldSet.find_by(internal_name: "loan_#{attrib}"),
          linkable_attribute: "loan_#{attrib}"
        )
      end

      root_questions = CustomField.loan_questions(attrib).roots.sort_by_required(@loan)
      @questions_json[attrib] = root_questions.map { |i| CustomFieldSerializer.new(i, loan: @loan) }.to_json
    end

    render layout: false
  end

  def update
    @loan = Loan.find(params[:id])
    authorize @loan
    @loan.assign_attributes(loan_params)

    if @loan.save
      redirect_to admin_loan_path(@loan), notice: I18n.t(:notice_updated)
    else
      prep_form_vars
      render :show
    end
  end

  def change_date
    @loan = Loan.find(params[:id])
    authorize @loan, :update?
    attrib = params[:which_date] == "loan_start" ? :signing_date : :target_end_date
    @loan.update_attributes(attrib => params[:new_date])
    render nothing: true
  end

  def create
    @loan = Loan.new(loan_params)
    authorize @loan

    if @loan.save
      redirect_to admin_loan_path(@loan), notice: I18n.t(:notice_created)
    else
      prep_form_vars
      render :new
    end
  end

  def destroy
    @loan = Loan.find(params[:id])
    authorize @loan

    if @loan.destroy
      redirect_to admin_loans_path, notice: I18n.t(:notice_deleted)
    else
      prep_form_vars
      render :show
    end
  end

  def print
    @loan = Loan.find(params[:id])
    authorize @loan, :show?
    @print_view = true
    @mode = params[:mode]
    @first_image = @loan.media.find {|item| item.kind == 'image'}
    prep_attached_links if @mode != "details-only"
  end

  private

  def loan_params
    params.require(:loan).permit(*(
      [
        :division_id, :organization_id, :loan_type_value, :status_value, :name,
        :amount, :currency_id, :primary_agent_id, :secondary_agent_id,
        :length_months, :rate, :signing_date, :first_payment_date, :first_interest_payment_date,
        :target_end_date, :projected_return, :representative_id,
        :project_type_value, :public_level_value
      ] + translation_params(:summary, :details)
    ))
  end

  def prep_form_vars
    @division_choices = division_choices
    @organization_choices = organization_policy_scope(Organization.all).order(:name)
    @agent_choices = person_policy_scope(Person.where(has_system_access: true)).order(:name)
    @currency_choices = Currency.all.order(:name)
    @representative_choices = representative_choices
  end

  def representative_choices
    raw_choices = @loan.organization ? @loan.organization.people : Person.all
    person_policy_scope(raw_choices).order(:name)
  end

  def prep_print_view
  end

  def prep_attached_links
    @attached_links = @loan.criteria_embedded_urls

    unless @attached_links.empty?
      open_link_text = view_context.link_to(I18n.t('loan.open_links', count: @attached_links.length),
        '#', data: {action: 'open-links', links: @attached_links})
      notice_text = "".html_safe
      notice_text << I18n.t('loan.num_of_links', count: @attached_links.length) << " " << open_link_text
      notice_text << " " << I18n.t('loan.popup_blocker') if @attached_links.length > 1
      flash.now[:alert] = notice_text
    end
  end
end
