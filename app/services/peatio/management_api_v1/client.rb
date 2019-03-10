# frozen_string_literal: true

module Peatio
  module ManagementAPIv1
    class Client < ::ManagementAPIv1::Client
      def initialize(*)
        super ENV.fetch('PEATIO_ROOT_URL'), Rails.configuration.x.peatio_management_api_v1_configuration
      end

      def create_withdraw(request_params = {})
        self.action = :write_withdraws
        jwt = payload(request_params.slice(:uid, :tid, :rid, :currency, :amount, :action))
                .yield_self { |payload| generate_jwt(payload) }
                .yield_self do |jwt|
                  action[:requires_barong_totp] ?
                    Barong::ManagementAPIv1::Client.new.otp_sign(request_params.merge(jwt: jwt, account_uid: request_params[:uid])) : jwt
                end
        request(:post, 'withdraws/new', jwt, jwt: true)
      end

      def show_accounts(request_params = {})
        self.action = :read_accounts
        jwt = payload(request_params.slice(:uid, :currency))
                  .yield_self { |payload| generate_jwt(payload) }
        request(:post, build_path('accounts/balance'), jwt, jwt: true)
      end

      def create_deposit(request_params = {})
        self.action = :write_deposits
        jwt = payload(request_params.slice(:uid, :currency, :amount))
                  .yield_self { |payload| generate_jwt(payload) }
        request(:post, build_path('deposits/new'), jwt, jwt: true)
      end

      def create_transfer(request_params = {})
        self.action = :write_transfers

        operations = [{
            currency:  request_params[:currency],
            amount:    request_params[:amount],
            account_src: {
                code:  request_params[:account_src],
                uid: nil
            },
            account_dst: {
                code:  request_params[:account_dst],
                uid:   request_params[:uid]
            }
        }]

        request_params[:operations] = operations

        jwt = payload(request_params.slice(:key, :kind, :desc, :operations))
                  .yield_self { |payload| generate_jwt(payload) }
        request(:post, build_path('transfers/new'), jwt, jwt: true)
      end

      def create_asset(request_params = {})
        self.action = :write_deposits
        jwt = payload(request_params.slice(:uid, :currency, :amount))
                  .yield_self { |payload| generate_jwt(payload) }
        request(:post, build_path('assets/new'), jwt, jwt: true)
      end

      def create_referral(request_params = {})
        self.action = :write_deposits
        jwt = payload(request_params.slice(:uid, :currency, :amount))
                  .yield_self { |payload| generate_jwt(payload) }
        Rails.logger.info "#{jwt.to_json}"
        request(:post, build_path('referral/new'), jwt, jwt: true)
      end
      def build_path(path)
        "api/v2/peatio/management/#{path}"
      end
    end
  end
end
