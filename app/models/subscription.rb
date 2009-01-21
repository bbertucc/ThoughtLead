class Subscription < ActiveRecord::Base
  include RecurringPayment

  belongs_to :user
  belongs_to :subscription_plan
  belongs_to :access_class

  validates_numericality_of :amount, :greater_than => 0
  validates_numericality_of :renewal_period, :only_integer => true, :greater_than => 0
  validates_inclusion_of :renewal_units, :in => units
  validates_inclusion_of :state, :in => ["pending", "active", "trial"]

  named_scope :trials_expiring_soon, lambda { |*args| { :conditions => { :state => 'trial', :next_renewal_at => (args.first || 7.days.from_now) } } }
  named_scope :due, lambda { |*args| { :conditions => { :state => 'active', :next_renewal_at => (args.first || Date.today) } } }

  before_destroy :destroy_gateway_record, :reset_access_class

  def has_billing_information?
    !needs_billing_information?
  end

  def needs_billing_information?
    billing_id.blank?
  end

  def trial_days_left
    next_renewal_at - Date.today if trial?
    0
  end

  def pending?
    self.state == "pending"
  end

  def active?
    self.state == "active"
  end

  def trial?
    self.state == "trial"
  end

  def plan=(plan)
    unless self.subscription_plan == plan
      [:amount, :renewal_period, :renewal_units, :access_class].each do |f|
        self.send("#{f}=", plan.send(f))
      end
      self.state = "pending"
      self.subscription_plan = plan
    end
  end

  def store_card(card, gw_options = {})
    # Clear out payment info if switching to CC from PayPal
    destroy_gateway_record(paypal) if paypal?

    response = if billing_id.blank?
      gateway.store(card, gw_options)
    else
      gateway.update(billing_id, card, gw_options)
    end

    if response.success?
      self.card_number = card.display_number
      self.card_expiration = "%02d-%d" % [card.expiry_date.month, card.expiry_date.year]
      self.billing_id = response.token
      return ensure_activation
    else
      errors.add_to_base(response.message)
      return false
    end
  end

  def ensure_activation
    if pending?
      #TODO: handle trial
      if !charge
        return false
      end

      user.access_class = access_class
      user.save
    end
    return true
  end

  def charge
    if amount == 0 || (response = gateway.purchase(amount_in_pennies, billing_id)).success?
      self.state = 'active'
      self.next_renewal_at = Date.today.advance({renewal_units => renewal_period}.symbolize_keys)

      save

      unless amount == 0
        description = "#{access_class.name} from #{Date.today} through #{next_renewal_at}"
        user.subscription_payments << SubscriptionPayment.new(:amount => amount, :description => description, :transaction_id => response.authorization)
      end
    else
      errors.add_to_base(response.message)
      return false
    end
  end

  def start_paypal(return_url, cancel_url)
    if (@response = paypal.setup_authorization(:return_url => return_url, :cancel_return_url => cancel_url, :description => AppConfig['app_name'])).success?
      paypal.redirect_url_for(@response.params['token'])
    else
      errors.add_to_base("PayPal Error: #{@response.message}")
      false
    end
  end

  def complete_paypal(token)
    if (@response = paypal.details_for(token)).success?
      if (@response = paypal.create_billing_agreement_for(token)).success?
        # Clear out payment info if switching to PayPal from CC
        destroy_gateway_record(cc) unless paypal?

        self.card_number = 'PayPal'
        self.card_expiration = 'N/A'
        set_billing
      else
        errors.add_to_base("PayPal Error: #{@response.message}")
        false
      end
    else
      errors.add_to_base("PayPal Error: #{@response.message}")
      false
    end
  end

  def needs_payment_info?
    self.card_number.blank? && self.subscription_plan.amount > 0
  end

  def paypal?
    card_number == 'PayPal'
  end

  protected

  def amount_in_pennies
    (amount * 100).to_i
  end

  def gateway
    paypal? ? paypal : cc
  end

  def paypal
    @paypal ||=  ActiveMerchant::Billing::Base.gateway(:paypal_express_reference_nv).new(gateway_config)
  end

  def cc
    @cc ||= ActiveMerchant::Billing::Base.gateway(:authorize_net_cim).new(gateway_config)
  end

  def destroy_gateway_record(gw = gateway)
    return if billing_id.blank?
    gw.unstore(billing_id)
    self.card_number = nil
    self.card_expiration = nil
    self.billing_id = nil
  end

  def reset_access_class
    self.user.access_class = nil
  end

  def gateway_config
    {:login => user.community.gateway_login, :password => user.community.gateway_password}
  end
end
