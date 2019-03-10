# frozen_string_literal: true

module Barong
  module ManagementAPIv1
    class Client < ::ManagementAPIv1::Client
      def initialize(*)
        super ENV.fetch('BARONG_ROOT_URL'), Rails.configuration.x.barong_management_api_v1_configuration
      end

      def otp_sign(request_params = {})
        self.action = :otp_sign
        params = request_params.slice(:account_uid, :otp_code, :jwt)
        request(:post, 'otp/sign', params)
      end

      def user_get(request_params = {})
        self.action = :read_users
        jwt = payload(request_params.slice(:uid))
                  .yield_self { |payload| generate_jwt(payload) }
        request(:post, build_path('users/get'), jwt, jwt: true)
      end

      def build_path(path)
        "api/v2/barong/management/#{path}"
      end
    end
  end
end
