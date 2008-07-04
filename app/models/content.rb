class Content < ActiveRecord::Base
  attr_accessor :uploaded_attachment_data
  validates_presence_of :title, :body, :teaser
  
  has_one :lesson
  has_one :article
  
  belongs_to :user
  has_many :attachments, :dependent => :destroy
  has_one :flash_video, :dependent => :destroy
  
  alias_attribute :to_s, :title
  
  # Adding an association with the user's community so that we can filter on community
  is_indexed :fields => ['title', 'body', 'teaser', 'draft'], :include => [{:association_name => 'user', :field => 'community_id'}]
  
  def access_level
    return "Premium" if self.premium?
    return "Registered" if self.registered?
    return "Public"
  end
  
  def access_level= (value)
    self.premium = (value == "Premium")
    self.registered = (value == "Registered")
  end
  
  def content_attachments=(it)
    for attachment in it
      if(!attachment.blank?)
        the_attachment = Attachment.new
        the_attachment.uploaded_data = attachment      
        self.attachments << the_attachment unless it.to_s.blank?  
      end
    end
  end
  
  def content_flash_video=(it)  
    the_flash_video = self.flash_video || FlashVideo.new
    the_flash_video.uploaded_data = it
    self.flash_video = the_flash_video unless it.to_s.blank?  
  end
  
end