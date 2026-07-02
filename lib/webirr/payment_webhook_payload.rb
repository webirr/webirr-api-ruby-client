# frozen_string_literal: true

module Webirr
  class PaymentWebhookPayload
    attr_reader :status, :data

    def initialize(payload)
      @payload = payload || {}
      @status = @payload["status"] || @payload[:status]
      @data = PaymentRecord.new(@payload["data"] || @payload[:data])
    end

    def valid?
      data.is_a?(PaymentRecord) && !data.empty?
    end
  end
end
