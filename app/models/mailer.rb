class Mailer < ActionMailer::Base
  
  def community_created(community, url)
    @from = "#{APP_NAME} <do-not-reply@#{APP_DOMAIN}>"
    @subject = "Welcome to Thoughtlead!"
    @sent_on = Time.now
    @body[:community] = community
    @body[:url] = url
    @recipients = community.owner.email
  end  
  
  def user_to_user_email(from, to, email)
    @from = "#{from} <do-not-reply@#{APP_DOMAIN}>"
    @subject = email.subject
    @sent_on = Time.now
    @body[:email] = email
    @recipients = to.email
    @headers["reply-to"] = from.email
  end
  
  def new_password(user, password)
    @recipients = user.email
    @subject = "Your New Password"
    @from = "#{user} <do-not-reply@#{APP_DOMAIN}>"
    @body[:name] = user.login
    @body[:password] = password
  end
  
  def new_user_welcome(user,message="If you have any questions or feedback, we'd love to hear from you.")
    @from = "#{user.community.name} <do-not-reply@#{APP_DOMAIN}>"
    @subject = "Welcome to #{user.community.name}"
    @sent_on = Time.now
    @body[:user] = user
    @body[:message] = message
    @recipients = user.email
  end
  
  def new_user_notice_to_owner(user)
    @from = "#{user.community.name} <do-not-reply@#{APP_DOMAIN}>"
    @subject = "#{user.community.name} has a new user"
    @sent_on = Time.now
    @body[:user] = user
    @recipients = user.community.owner.email
  end
  
end
