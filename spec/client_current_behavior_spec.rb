# frozen_string_literal: true

FakeWebirrResponse = Struct.new(:body, :status, :reason_phrase, :successful) do
  def success?
    successful
  end
end

FakeWebirrRequest = Struct.new(:body)
FakeWebirrCapturedRequest = Struct.new(:http_method, :path, :body)
FakeHTTPError = Struct.new(:response)

# Fake Faraday connection used to capture current Ruby SDK request behavior.
class FakeWebirrFaradayConnection
  attr_reader :requests

  def initialize(response)
    @response = response
    @requests = []
  end

  def post(path)
    request = FakeWebirrRequest.new
    yield request if block_given?
    @requests << FakeWebirrCapturedRequest.new(:post, path, request.body)
    @response
  end

  def put(path)
    request = FakeWebirrRequest.new
    yield request if block_given?
    @requests << FakeWebirrCapturedRequest.new(:put, path, request.body)
    @response
  end

  def delete(path)
    @requests << FakeWebirrCapturedRequest.new(:delete, path, nil)
    @response
  end

  def get(path)
    @requests << FakeWebirrCapturedRequest.new(:get, path, nil)
    @response
  end
end

# Shared helpers for current Ruby SDK behavior specs.
module RubySdkSpecHelpers
  RUBY_BILL_ATTRIBUTES = {
    amount: "120.45",
    customer_code: "C001",
    customer_name: "Yohannes Aregay Hailu",
    customer_phone: "0911000000",
    time: "2022-09-06 14:20:26",
    description: "Food delivery",
    bill_reference: "ruby/2022/001",
    merchant_id: "ruby",
    extras: { "source" => "ruby_spec" }.freeze
  }.freeze

  def sample_ruby_bill
    RUBY_BILL_ATTRIBUTES.each_with_object(Webirr::Bill.new) do |(attribute, value), bill|
      bill.public_send("#{attribute}=", value)
    end
  end
end

# rubocop:disable Metrics/BlockLength
RSpec.describe Webirr::Client do
  include RubySdkSpecHelpers

  it "configures the default test environment client" do
    _client, _connection, options = build_client(["merchant-from-client", "api-key", true])

    expect(options).to eq(
      url: "https://api.webirr.dev",
      params: { "api_key" => "api-key", "merchant_id" => "merchant-from-client" },
      headers: { "Content-Type" => "application/json" }
    )
  end

  it "configures the default production client" do
    _client, _connection, options = build_client(["merchant-from-client", "api-key", false])

    expect(options[:url]).to eq("https://api.webirr.net:8080")
  end

  it "keeps support for caller supplied domains" do
    _client, _connection, options =
      build_client(["merchant-from-client", "api-key", true], domain: "gateway.example.com:9443")

    expect(options[:url]).to eq("https://gateway.example.com:9443")
  end

  it "keeps support for caller supplied full URLs" do
    _client, _connection, options =
      build_client(["merchant-from-client", "api-key", true], domain: "https://gateway.example.com/")

    expect(options[:url]).to eq("https://gateway.example.com")
  end

  it "requires a nonblank merchant_id" do
    expect { described_class.new("  ", "api-key", true) }.to raise_error(ArgumentError, "merchant_id is required")
  end

  it "posts create_bill to the current bill endpoint" do
    client, connection = build_client(["merchant-from-client", "api-key", true])

    result = client.create_bill(sample_ruby_bill)

    expect(result).to eq("ok" => true)
    expect(connection.requests.last.http_method).to eq(:post)
    expect(connection.requests.last.path).to eq("einvoice/api/bill")
    expect(JSON.parse(connection.requests.last.body)).to include(
      "customerName" => "Yohannes Aregay Hailu",
      "customerPhone" => "0911000000",
      "billReference" => "ruby/2022/001",
      "merchantID" => "merchant-from-client"
    )
  end

  it "puts update_bill to the current bill endpoint" do
    client, connection = build_client(["merchant-from-client", "api-key", true])

    result = client.update_bill(sample_ruby_bill)

    expect(result).to eq("ok" => true)
    expect(connection.requests.last.http_method).to eq(:put)
    expect(connection.requests.last.path).to eq("einvoice/api/bill")
    expect(JSON.parse(connection.requests.last.body)).to include(
      "customerCode" => "C001",
      "amount" => "120.45",
      "description" => "Food delivery",
      "merchantID" => "merchant-from-client"
    )
  end

  it "deletes delete_bill through the current bill endpoint with encoded query" do
    client, connection = build_client(["merchant-from-client", "api-key", true])

    result = client.delete_bill("123 456 789")

    expect(result).to eq("ok" => true)
    expect(connection.requests.last).to have_attributes(
      http_method: :delete,
      path: "einvoice/api/bill?wbc_code=123+456+789",
      body: nil
    )
  end

  it "gets payment status from the current endpoint with encoded query" do
    client, connection = build_client(["merchant-from-client", "api-key", true])

    result = client.get_payment_status("123 456 789")

    expect(result).to eq("ok" => true)
    expect(connection.requests.last).to have_attributes(
      http_method: :get,
      path: "einvoice/api/paymentStatus?wbc_code=123+456+789",
      body: nil
    )
  end

  it "gets bill by reference from the current bill retrieval endpoint with encoded query" do
    client, connection = build_client(["merchant-from-client", "api-key", true])

    result = client.get_bill_by_reference("ruby/2022/001")

    expect(result).to eq("ok" => true)
    expect(connection.requests.last).to have_attributes(
      http_method: :get,
      path: "einvoice/api/bill?bill_reference=ruby%2F2022%2F001",
      body: nil
    )
  end

  it "gets bill by payment code from the current bill retrieval endpoint with encoded query" do
    client, connection = build_client(["merchant-from-client", "api-key", true])

    result = client.get_bill_by_payment_code("123 456 789")

    expect(result).to eq("ok" => true)
    expect(connection.requests.last).to have_attributes(
      http_method: :get,
      path: "einvoice/api/bill?wbc_code=123+456+789",
      body: nil
    )
  end

  it "gets payments with timestamp cursor from the current bulk polling endpoint" do
    client, connection = build_client(["merchant-from-client", "api-key", true])

    result = client.get_payments(last_timestamp: "20251231", limit: 10)

    expect(result).to eq("ok" => true)
    expect(connection.requests.last).to have_attributes(
      http_method: :get,
      path: "einvoice/api/payments?last_timestamp=20251231&limit=10",
      body: nil
    )
  end

  it "gets bills with payment status and timestamp cursor from the current list endpoint" do
    client, connection = build_client(["merchant-from-client", "api-key", true])

    result = client.get_bills(payment_status: -1, last_timestamp: "20251231", limit: 10)

    expect(result).to eq("ok" => true)
    expect(connection.requests.last).to have_attributes(
      http_method: :get,
      path: "einvoice/api/bills?payment_status=-1&last_timestamp=20251231&limit=10",
      body: nil
    )
  end

  it "gets merchant stat without dates from the current endpoint" do
    client, connection = build_client(["merchant-from-client", "api-key", true])

    result = client.get_stat

    expect(result).to eq("ok" => true)
    expect(connection.requests.last).to have_attributes(
      http_method: :get,
      path: "merchant/stat",
      body: nil
    )
  end

  it "gets merchant stat with date filters from the current endpoint" do
    client, connection = build_client(["merchant-from-client", "api-key", true])

    result = client.get_stat(date_from: "2026-01-01", date_to: "2026-01-31")

    expect(result).to eq("ok" => true)
    expect(connection.requests.last.path).to eq(
      "merchant/stat?date_from=2026-01-01&date_to=2026-01-31"
    )
  end

  it "gets supported banks from the current merchant bank endpoint" do
    client, connection = build_client(["merchant-from-client", "api-key", true])

    result = client.get_supported_banks

    expect(result).to eq("ok" => true)
    expect(connection.requests.last).to have_attributes(
      http_method: :get,
      path: "einvoice/api/banks",
      body: nil
    )
  end

  it "returns supported bank identifiers and display names" do
    response = FakeWebirrResponse.new(
      { "error" => nil, "res" => [{ "bankID" => "cbe_mobile", "name" => "CBE Mobile Banking" }] }.to_json,
      200,
      "OK",
      true
    )
    client, _connection = build_client(["merchant-from-client", "api-key", true], response: response)

    result = client.get_supported_banks

    expect(result["error"]).to be_nil
    expect(result["res"].first).to include(
      "bankID" => "cbe_mobile",
      "name" => "CBE Mobile Banking"
    )
  end

  it "parses the gateway webhook payment wrapper" do
    payload =
      Webirr::PaymentWebhookPayload.new(
        "status" => 2,
        "data" => {
          "status" => 2,
          "id" => 121_356,
          "bankID" => "cbe_mobile",
          "paymentReference" => "FTC356A577695",
          "paymentDate" => "2026-06-25 12:00:00",
          "time" => "2026-06-25 12:00:00",
          "confirmed" => true,
          "confirmedTime" => "2026-06-25 12:00:00",
          "canceled" => false,
          "canceledTime" => "",
          "amount" => "100.00",
          "wbcCode" => "000 000 000",
          "updateTimeStamp" => "2026062512000000000"
        }
      )

    expect(payload).to be_valid
    expect(payload.status).to eq(2)
    expect(payload.data).to include(
      "status" => 2,
      "bankID" => "cbe_mobile",
      "paymentReference" => "FTC356A577695",
      "wbcCode" => "000 000 000",
      "updateTimeStamp" => "2026062512000000000"
    )
  end

  it "returns the current error hash for failed responses" do
    response = FakeWebirrResponse.new("forbidden", 403, "Forbidden", false)
    client, _connection = build_client(["merchant-from-client", "api-key", true], response: response)

    expect(client.create_bill(sample_ruby_bill)).to eq(
      "error" => "http error 403 Forbidden"
    )
  end

  def build_client(client_args, response: success_response, **client_kwargs)
    options = nil
    connection = FakeWebirrFaradayConnection.new(response)

    allow(Faraday).to receive(:new) do |received_options|
      options = received_options
      connection
    end

    [described_class.new(*client_args, **client_kwargs), connection, options]
  end

  def success_response
    FakeWebirrResponse.new({ "ok" => true }.to_json, 200, "OK", true)
  end
end
# rubocop:enable Metrics/BlockLength

RSpec.describe Webirr::Bill do
  include RubySdkSpecHelpers

  it "serializes the current bill fields expected by the Ruby client" do
    expect(JSON.parse(sample_ruby_bill.to_json)).to eq(
      "customerCode" => "C001",
      "customerName" => "Yohannes Aregay Hailu",
      "customerPhone" => "0911000000",
      "amount" => "120.45",
      "description" => "Food delivery",
      "billReference" => "ruby/2022/001",
      "merchantID" => "ruby",
      "time" => "2022-09-06 14:20:26",
      "extras" => { "source" => "ruby_spec" }
    )
  end
end

RSpec.describe Webirr::PaymentStatus do
  it "exposes payment status constants and helpers" do
    expect(described_class::PENDING).to eq(0)
    expect(described_class::PAID_UNCONFIRMED).to eq(1)
    expect(described_class::PAID).to eq(2)
    expect(described_class::REVERSED).to eq(3)
    expect(described_class.paid?(2)).to be(true)
    expect(described_class.reversed?("3")).to be(true)
  end
end

RSpec.describe Webirr::TransientErrors do
  it "classifies Faraday timeout and connection errors as transient" do
    expect(described_class.is_transient(Faraday::TimeoutError.new("timeout"))).to be(true)
    expect(described_class.is_transient(Faraday::ConnectionFailed.new("connection failed"))).to be(true)
  end

  it "classifies retryable HTTP status responses as transient" do
    expect(described_class.is_transient(FakeHTTPError.new(status: 408))).to be(true)
    expect(described_class.is_transient(FakeHTTPError.new("status" => 429))).to be(true)
    expect(described_class.is_transient(FakeHTTPError.new(status: 502))).to be(true)
  end

  it "does not classify other client errors as transient" do
    expect(described_class.is_transient(FakeHTTPError.new(status: 400))).to be(false)
    expect(described_class.transient?(StandardError.new("bad input"))).to be(false)
  end
end
