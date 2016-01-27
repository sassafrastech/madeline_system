class Admin::Raw::NotesController < BaseCrudController


  protected

  # fields needed for initial model creation
  def create_attrs
    [:notable_type, :notable_id, :author_id]
  end

  def update_attrs
    [:notable_type, :notable_id, :author_id, :text]
  end


end