# frozen_string_literal: true

FakeWebirrResponse = Struct.new(:body, :status, :reason_phrase, :successful) do
  def success?
    successful
  end
end

FakeWebirrRequest = Struct.new(:body)
FakeWebirrCapturedRequest = Struct.new(:http_method, :path, :body)

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
    _client, _connection, options = build_client(["api-key", true])

    expect(options).to eq(
      url: "https://api.webirr.com/",
      params: { "api_key" => "api-key" },
      headers: { "Content-Type" => "application/json" }
    )
  end

  it "configures the default production client" do
    _client, _connection, options = build_client(["api-key", false])

    expect(options[:url]).to eq("https://api.webirr.com:8080/")
  end

  it "keeps support for caller supplied domains" do
    _client, _connection, options =
      build_client(["gateway.example.com", "api-key", true])

    expect(options[:url]).to eq("https://gateway.example.com/")
  end

  it "adds client merchant_id as a query parameter when supplied" do
    _client, _connection, options =
      build_client(["api-key", true], merchant_id: "0305")

    expect(options[:params]).to eq(
      "api_key" => "api-key",
      "merchant_id" => "0305"
    )
  end

  it "does not add blank client merchant_id as a query parameter" do
    _client, _connection, options =
      build_client(["api-key", true], merchant_id: "  ")

    expect(options[:params]).to eq("api_key" => "api-key")
  end

  it "posts create_bill to the current legacy endpoint" do
    client, connection = build_client(["api-key", true])

    result = client.create_bill(sample_ruby_bill)

    expect(result).to eq("ok" => true)
    expect(connection.requests.last.http_method).to eq(:post)
    expect(connection.requests.last.path).to eq("einvoice/api/postbill")
    expect(JSON.parse(connection.requests.last.body)).to include(
      "customerName" => "Yohannes Aregay Hailu",
      "customerPhone" => "0911000000",
      "billReference" => "ruby/2022/001",
      "merchantID" => "ruby"
    )
  end

  it "puts update_bill to the current legacy endpoint" do
    client, connection = build_client(["api-key", true])

    result = client.update_bill(sample_ruby_bill)

    expect(result).to eq("ok" => true)
    expect(connection.requests.last.http_method).to eq(:put)
    expect(connection.requests.last.path).to eq("einvoice/api/postbill")
    expect(JSON.parse(connection.requests.last.body)).to include(
      "customerCode" => "C001",
      "amount" => "120.45",
      "description" => "Food delivery"
    )
  end

  it "puts delete_bill to the current legacy endpoint" do
    client, connection = build_client(["api-key", true])

    result = client.delete_bill("abcd")

    expect(result).to eq("ok" => true)
    expect(connection.requests.last).to have_attributes(
      http_method: :put,
      path: "einvoice/api/deletebill?wbc_code=abcd",
      body: nil
    )
  end

  it "gets payment status from the current legacy endpoint" do
    client, connection = build_client(["api-key", true])

    result = client.get_payment_status("abcd")

    expect(result).to eq("ok" => true)
    expect(connection.requests.last).to have_attributes(
      http_method: :get,
      path: "einvoice/api/getPaymentStatus?wbc_code=abcd",
      body: nil
    )
  end

  it "gets bill by reference from the current bill retrieval endpoint" do
    client, connection = build_client(["api-key", true])

    result = client.get_bill_by_reference("ruby/2022/001")

    expect(result).to eq("ok" => true)
    expect(connection.requests.last).to have_attributes(
      http_method: :get,
      path: "einvoice/api/bill?bill_reference=ruby/2022/001",
      body: nil
    )
  end

  it "gets bill by payment code from the current bill retrieval endpoint" do
    client, connection = build_client(["api-key", true])

    result = client.get_bill_by_payment_code("abcd")

    expect(result).to eq("ok" => true)
    expect(connection.requests.last).to have_attributes(
      http_method: :get,
      path: "einvoice/api/bill?wbc_code=abcd",
      body: nil
    )
  end

  it "gets payments with timestamp cursor from the current bulk polling endpoint" do
    client, connection = build_client(["api-key", true])

    result = client.get_payments(last_timestamp: "20251231", limit: 10)

    expect(result).to eq("ok" => true)
    expect(connection.requests.last).to have_attributes(
      http_method: :get,
      path: "einvoice/api/payments?last_timestamp=20251231&limit=10",
      body: nil
    )
  end

  it "gets bills with payment status and timestamp cursor from the current list endpoint" do
    client, connection = build_client(["api-key", true])

    result = client.get_bills(payment_status: -1, last_timestamp: "20251231", limit: 10)

    expect(result).to eq("ok" => true)
    expect(connection.requests.last).to have_attributes(
      http_method: :get,
      path: "einvoice/api/bills?payment_status=-1&last_timestamp=20251231&limit=10",
      body: nil
    )
  end

  it "gets merchant stat without dates from the current endpoint" do
    client, connection = build_client(["api-key", true])

    result = client.get_stat

    expect(result).to eq("ok" => true)
    expect(connection.requests.last).to have_attributes(
      http_method: :get,
      path: "merchant/stat",
      body: nil
    )
  end

  it "gets merchant stat with date filters from the current endpoint" do
    client, connection = build_client(["api-key", true])

    result = client.get_stat(date_from: "2026-01-01", date_to: "2026-01-31")

    expect(result).to eq("ok" => true)
    expect(connection.requests.last.path).to eq(
      "merchant/stat?date_from=2026-01-01&date_to=2026-01-31"
    )
  end

  it "returns the current error hash for failed responses" do
    response = FakeWebirrResponse.new("forbidden", 403, "Forbidden", false)
    client, _connection = build_client(["api-key", true], response: response)

    expect(client.create_bill(sample_ruby_bill)).to eq(
      "error" => "http error 403 Forbidden"
    )
  end

  it "does not overwrite bill merchant_id from client merchant_id" do
    client, connection = build_client(["api-key", true], merchant_id: "0305")

    client.create_bill(sample_ruby_bill)

    expect(JSON.parse(connection.requests.last.body)).to include(
      "merchantID" => "ruby"
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
