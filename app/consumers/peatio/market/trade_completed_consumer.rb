# frozen_string_literal: true

module Peatio
  module Market
    class TradeCompletedConsumer
      def call(event)
        Rails.logger.info "Received trade event #{event}"
        if event[:buyer_income_fee].to_f > 0
          buyer_referral = Referral.new(trade_id: event[:id], kind: 'referral-payout', currency: event[:buyer_income_unit],
                                        amount: event[:buyer_income_fee].to_f * 0.1.to_f,
                                        user_uid: event[:buyer_uid], side: "buy")
          buyer_referral.accept! if buyer_referral.save!
          # buyer = Barong::ManagementAPIv1::Client.new.user_get(uid: event[:buyer_uid])
          # if buyer["referral_uid"].present?
          #   currency = Peatio::MemberAPIv2::Client.new.get_currency(event[:seller_income_unit])
          #   if currency["type"].present? && currency["type"] == "coin"
          #     Peatio::ManagementAPIv1::Client.new.create_transfer(key: Faker::Number.unique.number(10).to_i, kind: "referral-payout", desc: "referral", currency: event[:buyer_income_unit], amount: event[:buyer_income_fee].to_f * 0.1.to_f, account_src: 302, account_dst: 202, uid: buyer["referral_uid"])
          #   else
          #     Peatio::ManagementAPIv1::Client.new.create_transfer(key: Faker::Number.unique.number(10).to_i, kind: "referral-payout", desc: "referral", currency: event[:buyer_income_unit], amount: event[:buyer_income_fee].to_f * 0.1.to_f, account_src: 302, account_dst: 201, uid: buyer["referral_uid"])
          #   end
          # end

        end

        if event[:seller_income_fee].to_f > 0
          seller_referral = Referral.new(trade_id: event[:id], kind: 'referral-payout', currency: event[:seller_income_unit],
                                         amount: event[:seller_income_fee].to_f * 0.1.to_f,
                                         user_uid: event[:seller_uid], side: "sell")
          seller_referral.accept! if seller_referral.save!
          # seller = Barong::ManagementAPIv1::Client.new.user_get(uid: event[:seller_uid])
          # if seller["referral_uid"].present?
          #   currency = Peatio::MemberAPIv2::Client.new.get_currency(event[:seller_income_unit])
          #   if currency["type"] == "coin"
          #     Peatio::ManagementAPIv1::Client.new.create_transfer(key: Faker::Number.unique.number(10).to_i, kind: "referral-payout", desc: "referral", currency: event[:seller_income_unit], amount: event[:seller_income_fee].to_f * 0.1.to_f, account_src: 302, account_dst: 202, uid: seller["referral_uid"])
          #   else
          #     Peatio::ManagementAPIv1::Client.new.create_transfer(key: Faker::Number.unique.number(10).to_i, kind: "referral-payout", desc: "referral", currency: event[:seller_income_unit], amount: event[:seller_income_fee].to_f * 0.1.to_f, account_src: 302, account_dst: 201, uid: seller["referral_uid"])
          #   end
          # end
        end

      end

      class << self
        def call(event)
          new.call(event)
        end
      end
    end
  end
end
