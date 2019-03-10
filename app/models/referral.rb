class Referral < ApplicationRecord
  STATES = %i[submitted canceled rejected skipped accepted collected].freeze
  include AASM
  include AASM::Locking

  validates :trade_id, :key, :aasm_state, :user_uid, :currency_type, :kind, :side, :account_dst, :account_src, presence: true
  validates :amount,
            numericality: {
                greater_than_or_equal_to: 0
            }
  before_validation :currency_check
  validate :user_present
  before_validation :referrer_present
  before_validation :set_key
  before_validation {self.completed_at ||= Time.current if completed? }
  before_validation :from_account?
  before_validation :to_account?

  aasm whiny_transitions: false do
    state :submitted, initial: true
    state :canceled
    state :rejected
    state :accepted
    state :skipped
    state :collected
    event(:cancel) {transitions from: :submitted, to: :canceled}
    event(:reject) {transitions from: :submitted, to: :rejected}
    event :accept do
      transitions from: :submitted, to: :accepted
      after do
        plus_funds
      end
    end
    event :skip do
      transitions from: :accepted, to: :skipped
    end
    event :dispatch do
      transitions from: %i[accepted skipped], to: :collected
    end
  end

  def dispatch_after_plus_funds
    self.dispatch!
  end
  def completed?
    !submitted?
  end

  def set_key
    return unless key.blank?

    loop do
      self.key = Faker::Number.unique.number(6)
      break unless Referral.where(key: key).any?
    end
  end

  def set_currency_type
    currency = currency?
    if !currency?.nil?
      self.currency_type = currency?
    end
  end

  def plus_funds
    return self.skip! if amount.to_f <= 0

    transfer = Peatio::ManagementAPIv1::Client.new.create_transfer(
        key: key.to_i, kind: kind, desc: "referral",
        currency: currency, amount: amount.to_f,
        account_src: account_src, account_dst: account_dst, uid: referrer_uid)
    return dispatch_after_plus_funds if transfer["key"]
  rescue => e
    self.reason = "Error is #{e}"
    self.reject!
  end

  def currency_check
    currency_alt = currency?
    return false if currency_alt.nil?
    self.currency_type = currency_alt["type"]
  end

  def user_present
    true if Barong::ManagementAPIv1::Client.new.user_get(uid: user_uid)
  rescue => e
    self.reason = 'User not present'
    self.reject!
    false
  end

  def referrer_present?
    true if Barong::ManagementAPIv1::Client.new.user_get(uid: referrer_uid)
  rescue => e
    false
  end

  def to_account?
    return self.account_dst = '202' if currency_type == 'coin'
    self.account_dst = '201' if currency_type == 'fiat'
  end

  def from_account?
    return self.account_src = '302' if currency_type == 'coin' && kind == 'referral-payout'
    self.account_src = '301' if currency_type == 'fiat' && kind == 'referral-payout'
  end

  def referrer_present
    return unless user_present
    referrer = Barong::ManagementAPIv1::Client.new.user_get(uid: user_uid)
    if referrer["referral_uid"].present?
      self.referrer_uid = referrer["referral_uid"]
    else
      self.reason = 'Referral UID not present'
      self.reject!
      return false
    end
  rescue => e
    self.reason = 'Referral UID not present'
    self.reject!
    false
  end

  def currency?
    Peatio::MemberAPIv2::Client.new.get_currency(currency)
  rescue => e
    false
  end
end
