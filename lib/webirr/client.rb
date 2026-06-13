# frozen_string_literal: true

require "faraday"

module Webirr
  class Client
    def initialize(domain = "api.webirr.com", api_key, is_test_env, merchant_id: nil)
      @api_key = api_key
      @merchant_id = merchant_id
      @client =
        Faraday.new(
          url:
            (is_test_env ? "https://#{domain}/" : "https://#{domain}:8080/").to_s,
          params: client_params,
          headers: {
            "Content-Type" => "application/json"
          }
        )
    end

    def create_bill(bill)
      response =
        @client.post("einvoice/api/postbill") { |req| req.body = bill.to_json }
      decode_response(response)
    end

    def update_bill(bill)
      response =
        @client.put("einvoice/api/postbill") { |req| req.body = bill.to_json }
      decode_response(response)
    end

    def delete_bill(payment_code)
      response = @client.put("einvoice/api/deletebill?wbc_code=#{payment_code}")
      decode_response(response)
    end

    def get_payment_status(payment_code)
      response =
        @client.get("einvoice/api/getPaymentStatus?wbc_code=#{payment_code}")
      decode_response(response)
    end

    def get_bill_by_reference(bill_reference)
      response = @client.get("einvoice/api/bill?bill_reference=#{bill_reference}")
      decode_response(response)
    end

    def get_bill_by_payment_code(payment_code)
      response = @client.get("einvoice/api/bill?wbc_code=#{payment_code}")
      decode_response(response)
    end

    def get_payments(last_timestamp: "", limit: 100)
      response = @client.get("einvoice/api/payments?last_timestamp=#{last_timestamp}&limit=#{limit}")
      decode_response(response)
    end

    def get_bills(payment_status: -1, last_timestamp: "", limit: 100)
      response = @client.get(
        "einvoice/api/bills?payment_status=#{payment_status}&last_timestamp=#{last_timestamp}&limit=#{limit}"
      )
      decode_response(response)
    end

    def get_stat(date_from: nil, date_to: nil)
      if date_from.nil?
        response = @client.get("merchant/stat")
      else
        response = @client.get("merchant/stat?date_from=#{date_from}&date_to=#{date_to}")
      end
      decode_response(response)
    end

    private

    def decode_response(response)
      if response.success?
        JSON.parse(response.body)
      else
        { "error" => "http error #{response.status} #{response.reason_phrase}" }
      end
    end

    def client_params
      params = { "api_key" => @api_key }
      params["merchant_id"] = @merchant_id.to_s unless @merchant_id.to_s.strip.empty?
      params
    end
  end
end
