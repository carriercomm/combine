class Invoice < ActiveRecord::Base
  attr_accessible :amount, :client_id, :fee, :paid, :token, :number, :stripe_charge_hash

  attr_accessor :stripe_card_token

  belongs_to :client

  before_create :create_token


  def create_token
    self.token = SecureRandom.hex(12)
  end

  def total
    @my_total ||= self.amount * (1 + self.fee)
  end

  def pay(token)
    c = Stripe::Charge.create(
      :amount => (self.total*100).round,
      :currency => "usd",
      :card => token, # obtained with Stripe.js
      :description => "Payment for invoice #{self.number} by #{self.client.email}"
    )
    self.stripe_charge_hash = c[:id]
    save!
  rescue Stripe::CardError => e
    logger.error "Stripe error while charging card: #{e.message}"
    errors.add :base, "There was a problem with your credit card. It may have been declined. Please contact #{SUPPORT_EMAIL} for help."
    false
  end

  def paid?
    !self.stripe_charge_hash.blank?
  end
end
