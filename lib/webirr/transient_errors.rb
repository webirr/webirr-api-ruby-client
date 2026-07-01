# frozen_string_literal: true

require "faraday"

module Webirr
  module TransientErrors
    RETRYABLE_STATUS_CODES = [408, 429].freeze

    # rubocop:disable Naming/PredicateName
    def self.is_transient(error)
      return true if error.is_a?(Faraday::TimeoutError) || error.is_a?(Faraday::ConnectionFailed)

      status = status_code(error)
      return false if status.nil?

      RETRYABLE_STATUS_CODES.include?(status) || status >= 500
    end
    # rubocop:enable Naming/PredicateName

    def self.transient?(error)
      is_transient(error)
    end

    def self.status_code(error)
      response = error.respond_to?(:response) ? error.response : nil
      return nil if response.nil?

      value =
        if response.respond_to?(:status)
          response.status
        elsif response.respond_to?(:[])
          response[:status] || response["status"]
        end

      value&.to_i
    end

    private_class_method :status_code
  end
end
