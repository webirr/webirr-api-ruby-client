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
      if response.success?
        JSON.parse(response.body)
      else
        { "error" => "http error #{response.status} #{response.reason_phrase}" }
      end
    end

    def update_bill(bill)
      response =
        @client.put("einvoice/api/postbill") { |req| req.body = bill.to_json }
      if response.success?
        JSON.parse(response.body)
      else
        { "error" => "http error #{response.status} #{response.reason_phrase}" }
      end
    end

    def delete_bill(payment_code)
      response = @client.put("einvoice/api/deletebill?wbc_code=#{payment_code}")
      if response.success?
        JSON.parse(response.body)
      else
        { "error" => "http error #{response.status} #{response.reason_phrase}" }
      end
    end

    def get_payment_status(payment_code)
      response =
        @client.get("einvoice/api/getPaymentStatus?wbc_code=#{payment_code}")
      if response.success?
        JSON.parse(response.body)
      else
        { "error" => "http error #{response.status} #{response.reason_phrase}" }
      end
    end

    def get_stat(date_from: nil, date_to: nil)
      if date_from.nil?
        response = @client.get("merchant/stat")
      else
        response = @client.get("merchant/stat?date_from=#{date_from}&date_to=#{date_to}")
      end
      if response.success?
        JSON.parse(response.body)
      else
        { "error" => "http error #{response.status} #{response.reason_phrase}" }
      end
    end

    private

    def client_params
      params = { "api_key" => @api_key }
      params["merchant_id"] = @merchant_id.to_s unless @merchant_id.to_s.strip.empty?
      params
    end
  end
end
