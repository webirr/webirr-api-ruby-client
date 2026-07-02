# frozen_string_literal: true

require "json"
require "webirr"

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
# Webhook handler for processing payment updates from WeBirr.
# This endpoint should be hosted on a secure server with HTTPS enabled.
class Webhook
  # Handle incoming webhook POST requests.
  # Validate request method and check authentication using authKey from the query string.
  def handle_request(method, provided_auth_key, raw_payload)
    return json_response(405, "error" => "Method Not Allowed. POST required.") unless method.to_s.upcase == "POST"

    unless authenticated?(provided_auth_key)
      return json_response(403, "error" => "Unauthorized access. Invalid authKey.")
    end

    return json_response(400, "error" => "Empty request body.") if raw_payload.to_s.empty?

    payload = JSON.parse(raw_payload)
    webhook_payload = Webirr::PaymentWebhookPayload.new(payload)

    return json_response(400, "error" => "Invalid payment data.") unless webhook_payload.valid?

    process_payment(webhook_payload.data)

    json_response(200, "success" => true, "message" => "Payment received and queued for processing")
  rescue JSON::ParserError
    json_response(400, "error" => "Invalid JSON format.")
  end

  private

  def authenticated?(provided_auth_key)
    expected_auth_key = ENV.fetch("WEBIRR_WEBHOOK_AUTH_KEY", "YOUR_WEBHOOK_AUTH_KEY")
    secure_compare(expected_auth_key.to_s, provided_auth_key.to_s)
  end

  def secure_compare(expected, provided)
    return false if expected.empty? || provided.empty?
    return false unless expected.bytesize == provided.bytesize

    expected_bytes = expected.bytes
    result = 0
    provided.each_byte.with_index { |byte, index| result |= byte ^ expected_bytes[index] }
    result.zero?
  end

  # Process Payment should be implemented as idempotent operation for production use cases.
  # This method and logic can be shared among all payment processing consumers:
  # 1. bulk polling, 2. webhook, 3. single payment polling.
  def process_payment(payment)
    puts "\nPayment Status: #{payment["status"]}"
    puts "\nbill is paid" if Webirr::PaymentStatus.paid?(payment["status"])
    puts "\nbill payment is reversed" if Webirr::PaymentStatus.reversed?(payment["status"])
    puts "\nBank: #{payment["bankID"]}"
    puts "\nBank Reference Number: #{payment["paymentReference"]}"
    puts "\nAmount Paid: #{payment["amount"]}"
    puts "\nPayment Date: #{payment["paymentDate"] || payment["time"]}"
    puts "\nReversal/Cancel Date: #{payment["canceledTime"]}"
    puts "\nUpdate Timestamp: #{payment["updateTimeStamp"]}"
  end

  def json_response(status_code, body)
    { status_code: status_code, content_type: "application/json", body: body.to_json }
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
