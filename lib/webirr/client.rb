# frozen_string_literal: true

require "faraday"
require "uri"

module Webirr
  class Client
    DEFAULT_TEST_BASE_URL = "https://api.webirr.dev"
    DEFAULT_PROD_BASE_URL = "https://api.webirr.net:8080"

    def initialize(merchant_id, api_key, is_test_env, domain: nil)
      @api_key = api_key.to_s
      @merchant_id = normalize_required_merchant_id(merchant_id)
      @client =
        Faraday.new(
          url: resolve_base_url(is_test_env, domain),
          params: client_params,
          headers: {
            "Content-Type" => "application/json"
          }
        )
    end

    def create_bill(bill)
      prepare_bill(bill)
      decode_response(@client.post("einvoice/api/bill") { |req| req.body = bill.to_json })
    end

    def update_bill(bill)
      prepare_bill(bill)
      decode_response(@client.put("einvoice/api/bill") { |req| req.body = bill.to_json })
    end

    def delete_bill(payment_code)
      decode_response(@client.delete(path_with_query("einvoice/api/bill", wbc_code: payment_code)))
    end

    def get_payment_status(payment_code)
      decode_response(@client.get(path_with_query("einvoice/api/paymentStatus", wbc_code: payment_code)))
    end

    def get_bill_by_reference(bill_reference)
      decode_response(@client.get(path_with_query("einvoice/api/bill", bill_reference: bill_reference)))
    end

    def get_bill_by_payment_code(payment_code)
      decode_response(@client.get(path_with_query("einvoice/api/bill", wbc_code: payment_code)))
    end

    def get_payments(last_timestamp: "", limit: 100)
      path = path_with_query("einvoice/api/payments", last_timestamp: last_timestamp, limit: limit)
      decode_response(@client.get(path))
    end

    def get_bills(payment_status: -1, last_timestamp: "", limit: 100)
      response =
        @client.get(
          path_with_query(
            "einvoice/api/bills",
            payment_status: payment_status,
            last_timestamp: last_timestamp,
            limit: limit
          )
        )
      decode_response(response)
    end

    def get_stat(date_from: nil, date_to: nil)
      path = date_from.nil? ? "merchant/stat" : path_with_query("merchant/stat", date_from: date_from, date_to: date_to)
      decode_response(@client.get(path))
    end

    # rubocop:disable Naming/AccessorMethodName
    def get_supported_banks
      decode_response(@client.get("einvoice/api/banks"))
    end
    # rubocop:enable Naming/AccessorMethodName

    private

    def normalize_required_merchant_id(merchant_id)
      normalized = merchant_id.to_s.strip
      raise ArgumentError, "merchant_id is required" if normalized.empty?

      normalized
    end

    def resolve_base_url(is_test_env, domain)
      custom_domain = domain.to_s.strip
      return normalize_domain(custom_domain) unless custom_domain.empty?

      is_test_env ? DEFAULT_TEST_BASE_URL : DEFAULT_PROD_BASE_URL
    end

    def normalize_domain(domain)
      value = domain.start_with?("http://", "https://") ? domain : "https://#{domain}"
      value.sub(%r{/+\z}, "")
    end

    def prepare_bill(bill)
      bill.merchant_id = @merchant_id
    end

    def path_with_query(path, params)
      "#{path}?#{URI.encode_www_form(params)}"
    end

    def decode_response(response)
      if response.success?
        JSON.parse(response.body)
      else
        { "error" => "http error #{response.status} #{response.reason_phrase}" }
      end
    end

    def client_params
      { "api_key" => @api_key, "merchant_id" => @merchant_id }
    end
  end
end
