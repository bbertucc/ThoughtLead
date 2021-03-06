class AdminController < ApplicationController
  before_filter :owner_login_required

  def edit_community
    @community = current_community

    return if request.get?

    return unless @community.update_attributes(params[:community])

    flash[:notice] = "Community Settings Saved"
    redirect_to edit_community_url
  end

  def subscription_plans

  end

  def export_users
    begin
      since = Date.new(params[:date][:year].to_i, params[:date][:month].to_i, params[:date][:day].to_i)
    rescue ArgumentError
      flash[:notice] = "You have entered an invalid date."
      redirect_to select_exported_users_url
      return
    end

    premium_condition = params[:premium] == 'true' ? "access_class_id is not null" : "access_class_id is null"
    users = User.find(:all, :conditions => ["created_at >= ? and community_id = ? and " + premium_condition, since, current_community.id])
    csv_string = FasterCSV.generate do |csv|
      csv << ["first_name","last_name","email"]
      users.each do |u|
        csv << [u.first_name, u.last_name, u.email]
      end
    end
    send_data csv_string, :type => "text/plain",
    :filename=>"export_users.csv",
    :disposition => 'attachment'
  end

  def select_exported_users
  end
end
