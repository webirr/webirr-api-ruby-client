# frozen_string_literal: true

module Webirr
  class PaymentRecord
    def initialize(data = {})
      @data = stringify_keys(data || {})
      @data.delete("time")
    end

    def [](key)
      @data[key.to_s]
    end

    def to_h
      @data.dup
    end

    def empty?
      @data.empty?
    end

    def paid?
      self["status"].to_i == PaymentStatus::PAID
    end

    def reversed?
      self["status"].to_i == PaymentStatus::REVERSED
    end

    private

    def stringify_keys(data)
      data.each_with_object({}) do |(key, value), result|
        result[key.to_s] = value
      end
    end
  end
end
