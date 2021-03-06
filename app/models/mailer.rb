class Mailer < ActionMailer::Base
  def community_created(community, url)
    @from = "#{APP_NAME} <do-not-reply@#{APP_DOMAIN}>"
    @subject = "Welcome to Thoughtlead!"
    @sent_on = Time.now
    @body[:community] = community
    @body[:url] = url
    @recipients = community.owner.email
    @headers["x-custom-ip-tag"] = "thoughtlead"
  end

  def user_to_user_email(from, to, email)
    @from = "#{to.community.name} <do-not-reply@#{to.community.host}>"
    @subject = email.subject
    @sent_on = Time.now
    @body[:email] = email
    @recipients = to.email
    @headers["reply-to"] = from.email
    @headers["x-custom-ip-tag"] = "thoughtlead"
  end

  def new_password(user, password)
    @from = "#{user.community.name} <do-not-reply@#{user.community.host}>"
    @recipients = user.email
    @subject = "Your New Password"
    @body[:name] = user.login
    @body[:password] = password
    @headers["x-custom-ip-tag"] = "thoughtlead"
  end

  def new_user_welcome(user, newpassword, login_url)
    # FROM: (Community Name) (admin's email address)
    # Subject: Welcome to (Community Name)
    @from = "#{user.community.name} <#{user.community.owner.email}>"
    @subject = "Welcome to #{user.community.name}"
    @sent_on = Time.now
    @body[:user] = user
    @body[:newpassword] = newpassword
    @body[:login_url] = login_url
    @recipients = user.email
    @headers["x-custom-ip-tag"] = "thoughtlead"
  end

  def new_user_notice_to_owner(user)
    @from = "#{user.community.name} <do-not-reply@#{user.community.host}>"
    @subject = "#{user.community.name} has a new user"
    @sent_on = Time.now
    @body[:user] = user
    @recipients = user.community.owner.email
    @headers["x-custom-ip-tag"] = "thoughtlead"
  end
end
