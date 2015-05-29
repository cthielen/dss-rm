module Api
  module V1
    class GroupsController < ApplicationController
      before_filter :load_group, :only => :show
      filter_access_to :all, :attribute_check => false

      def show
        if @group
          logger.tagged('API') { logger.info "#{current_user.log_identifier}@#{request.remote_ip}: Loaded group view (show) for #{@group.id}." }

          @cache_key = "api/groups/" + @group.id.to_s + '/' + @group.updated_at.try(:utc).try(:to_s, :number)

          render "api/v1/groups/show"
        else
          logger.tagged('API') { logger.info "#{current_user.log_identifier}@#{request.remote_ip}: Attempted to load group view (show) for invalid ID #{params[:id]}." }
          render :text => "Invalid group ID '#{params[:id]}'.", :status => 404
        end
      end

      private

      def load_group
        begin
          @group = Group.with_permissions_to(:read).find_by_id(params[:id])
        rescue ActiveRecord::RecordNotFound
          # This exception is acceptable. We catch it to avoid triggering the
          # uncaught exceptions handler in ApplicationController.
        end
      end
    end
  end
end