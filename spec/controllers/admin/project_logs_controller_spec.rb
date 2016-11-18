require 'rails_helper'

RSpec.describe Admin::ProjectLogsController, type: :controller do
  describe "create" do
    before do
      @user = sign_in_admin
      @user.division.people << create(:person, :with_admin_access)
    end

    let(:log) { build(:project_log) }

    context "with division set to notify" do
      before { log.division.update(notify_on_new_logs: true) }

      context "with notify checked" do
        let(:notify) { true }

        it "enqueues and sends notification email", focus: true do
          expect do
            post :create, project_log: log.attributes, notify: notify
          end.to change { Delayed::Job.count }.by(1)
          expect do
            @dj_result = Delayed::Worker.new.work_off
          end.to change { ActionMailer::Base.deliveries.size }.by(2)
          expect(@dj_result).to eq [1, 0] # successes, failures
        end
      end

      context "with notify unchecked" do
        let(:notify) { false }

        it "doesn't send email" do
          expect do
            post :create, project_log: log.attributes, notify: notify
            Delayed::Worker.new.work_off
          end.to change { ActionMailer::Base.deliveries.size }.by(0)
        end
      end
    end

    context "with division not set to notify" do
      it "doesn't send email" do
        expect do
          post :create, project_log: log.attributes, notify: true
          Delayed::Worker.new.work_off
        end.to change { ActionMailer::Base.deliveries.size }.by(0)
      end
    end
  end
end
