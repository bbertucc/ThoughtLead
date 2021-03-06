class CommunitiesController < ApplicationController
  layout :community_layout

  before_filter :community_is_active, :except => [ :need_to_activate, :new, :create, :choose_plan, :index ]
  before_filter :super_admin_login_required, :only => [ :index, :toggle_community_activation ]

  def index
    @communities = Community.find(:all)
  end

  def current_community_home
    if logged_in?
      render :file => themed_file("community_home_login.html.erb"), :layout => true
    else
      render :file => themed_file("community_home.html.erb"), :layout => true
    end
  end

  def current_community_about
    render :file => themed_file("community_about.html.erb"), :layout => true
  end

  def current_community_contact
    render :file => themed_file("community_contact.html.erb"), :layout => true
  end

  def current_community_tos
    render :file => themed_file("community_tos.html.erb"), :layout => false
  end

  def new
    @community = Community.new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    @community = Community.new(params[:community])

    @community.valid?
    if !@user.valid? || !@community.valid?
      render(:action => :new)
      return
    end

    @user.community = @community
    @user.save
    @community.owner = @user
    @community.save

    Mailer.deliver_community_created(@community, community_dashboard_url(@community))

    flash[:notice] = "Successfully created your community."

    #TODO this is broken for local machines as it does not include the port
    redirect_to community_login_url(@community)
  end

  def toggle_activation
    id = params[:id]
    community = Community.find_by_id(id)
    if (community != current_community)
      community.active = !community.active
      community.save
    end
    redirect_to communities_url
  end

  private

  def community_layout
    ['new', 'choose_plan', 'index', 'create'].include?(params[:action]) ? 'community_home' : 'application'
  end
end
