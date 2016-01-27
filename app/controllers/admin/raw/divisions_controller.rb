class Admin::Raw::DivisionsController < BaseCrudController


  def select
    logger.info "select_division - params: #{params}"
    set_current_division_id(params["division_id"])
    redirect_to selected_nav_path
  end


  protected

  def update_attrs
    [:name, :description]
  end


end