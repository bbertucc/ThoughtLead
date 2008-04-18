module AuthenticatedSystem
  protected
    def logged_in?
      current_user != :false
    end
    
    def logged_in_as_owner?
      logged_in? && current_user.owner?
    end  

    def logged_in_as_active?
      logged_in? && current_user.active
    end  
    
    def current_user
      @current_user ||= (session[:user] && User.find_by_id(session[:user])) || :false
    end
    
    def current_user=(new_user)
      session[:user] = (new_user.nil? || new_user.is_a?(Symbol)) ? nil : new_user.id
      @current_user = new_user
    end
    
    def authorized?
      true
    end

    def login_required
      username, passwd = get_auth_data
      self.current_user ||= current_community.authenticate(username, passwd) || :false if username && passwd
      logged_in? && authorized? ? true : access_denied
    end
    
    def owner_login_required
      return access_denied unless logged_in? && authorized?
      return true if current_user.owner?

      flash[:warning] = "You do not have permission to access that part of the site."
      redirect_to login_url
      false
    end
    
    def access_denied
      respond_to do |accepts|
        accepts.html {
          store_location
          flash[:warning] = "You must login to access that part of the site."
          redirect_to login_url
        }
        accepts.xml {
          headers["Status"]           = "Unauthorized"
          headers["WWW-Authenticate"] = %(Basic realm="Web Password")
          render :text => "HTTP Basic: Access denied.", :status => '401 Unauthorized'
        }
      end
      false
    end  
    
    def store_location
      session[:return_to] = request.request_uri
    end
    
    def redirect_back_or_default(default)
      session[:return_to] ? redirect_to(session[:return_to]) : redirect_to(default)
      session[:return_to] = nil
    end
    
    def self.included(base)
      base.send :helper_method, :current_user, :logged_in?, :logged_in_as_owner?, :logged_in_as_active?
    end

    def login_from_cookie
      return unless cookies[:auth_token] && !logged_in?
      user = User.find_by_remember_token(cookies[:auth_token])
      if user && user.remember_token?
        user.remember_me
        self.current_user = user
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
        flash[:notice] = "Logged in successfully"
      end
    end

  private
    @@http_auth_headers = %w(X-HTTP_AUTHORIZATION HTTP_AUTHORIZATION Authorization)
    def get_auth_data
      auth_key  = @@http_auth_headers.detect { |h| request.env.has_key?(h) }
      auth_data = request.env[auth_key].to_s.split unless auth_key.blank?
      return auth_data && auth_data[0] == 'Basic' ? Base64.decode64(auth_data[1]).split(':')[0..1] : [nil, nil] 
    end
end
