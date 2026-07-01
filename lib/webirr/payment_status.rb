# frozen_string_literal: true

module Webirr
  module PaymentStatus
    PENDING = 0
    PAID_UNCONFIRMED = 1
    PAID = 2
    REVERSED = 3

    def self.paid?(status)
      status.to_i == PAID
    end

    def self.reversed?(status)
      status.to_i == REVERSED
    end
  end
end
