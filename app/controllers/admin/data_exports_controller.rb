class Admin::DataExportsController < Admin::AdminController

  def new
    authorize :data_export
    if params.has_key?(:type)
      set_export_class_on_new
      @data_export = @export_class.new(
        locale_code: I18n.locale,
        division: current_division
      )
    else
      render :choose_type
    end
  end

  def create
    @export_class = data_export_create_params[:type].constantize
    @data_export = @export_class.new(data_export_create_params)
    authorize @data_export
    if @data_export.save
      Task.create(
        job_class: DataExportTaskJob,
        job_type_value: 'data_export_task_job',
        activity_message_value: 'task_enqueued',
        taskable: @data_export
      ).enqueue(job_params: {data_export_id: @data_export.id})
    else
      render :new
    end
  end

  def index
    authorize :data_export

    @data_exports = DataExport.all

    @data_exports_grid = initialize_grid(
      policy_scope(DataExport),
      include: [:attachments],
      order: "created_at",
      order_direction: "desc",
      per_page: 50,
      name: "data_exports",
      enable_export_to_csv: true
    )

    @csv_mode = true
    @enable_export_to_csv = true

    export_grid_if_requested('data_exports': 'data_exports_grid_definition') do
      # This block only executes if CSV is not being returned
      @csv_mode = false
    end
  end

  def show
    @data_export = DataExport.find(params[:id])
    authorize @data_export
  end

  private

  def set_export_class_on_new
    @export_class = DataExport::DATA_EXPORT_TYPES[data_export_new_params[:type]].constantize
  end

  def data_export_new_params
    params.permit(:type)
  end

  def data_export_create_params
    params.require(:data_export).permit(:type, :division_id, :locale_code, :name)
  end
end
