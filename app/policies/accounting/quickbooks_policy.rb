class Accounting::QuickbooksPolicy < ApplicationPolicy
  def authenticate?
    division_admin(division: Division.root)
  end

  def oauth_callback?
    division_admin(division: Division.root)
  end

  def disconnect?
    division_admin(division: Division.root)
  end

  def full_sync?
    division_admin(division: Division.root)
  end
end
