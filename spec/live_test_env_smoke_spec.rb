# frozen_string_literal: true

require "securerandom"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Live TestEnv smoke tests" do
  before do
    skip_message = "Set WEBIRR_TEST_ENV_MERCHANT_ID and WEBIRR_TEST_ENV_API_KEY to run live smoke tests"
    skip skip_message unless test_env_configured?
  end

  it "creates, updates, retrieves, polls, and deletes a TestEnv bill" do
    client = Webirr::Client.new(test_env_api_key, true, merchant_id: test_env_merchant_id)
    payment_code = nil

    supported_banks = client.get_supported_banks
    expect_success(supported_banks)
    expect(supported_banks["res"]).to be_a(Array)
    expect(supported_banks["res"]).not_to be_empty
    supported_banks["res"].each do |bank|
      expect(bank["bankID"].to_s).not_to be_empty
      expect(bank["name"].to_s).not_to be_empty
    end

    bill = build_live_bill
    create_result = client.create_bill(bill)
    expect_success(create_result)

    payment_code = create_result["res"].to_s
    expect(payment_code).not_to be_empty

    bill.amount = "121.45"
    bill.customer_name = "John ruby"
    update_result = client.update_bill(bill)
    expect_success(update_result)

    by_reference_result = client.get_bill_by_reference(bill.bill_reference)
    expect_success(by_reference_result)
    expect(by_reference_result["res"]).not_to be_nil

    by_payment_code_result = client.get_bill_by_payment_code(payment_code)
    expect_success(by_payment_code_result)
    expect(by_payment_code_result["res"]).not_to be_nil

    status_result = client.get_payment_status(payment_code)
    expect_success(status_result)
    expect(status_result["res"]).not_to be_nil

    bills_result = client.get_bills(payment_status: -1, last_timestamp: "20251231", limit: 10)
    expect_success(bills_result)
    expect(bills_result["res"]).not_to be_nil

    payments_result = client.get_payments(last_timestamp: "20251231", limit: 10)
    expect_success(payments_result)
    expect(payments_result["res"]).not_to be_nil

    delete_result = client.delete_bill(payment_code)
    expect_success(delete_result)
    payment_code = nil
  ensure
    client.delete_bill(payment_code) if defined?(client) && payment_code.to_s != ""
  end

  def build_live_bill
    live_bill_attributes.each_with_object(Webirr::Bill.new) do |(attribute, value), bill|
      bill.public_send("#{attribute}=", value)
    end
  end

  def live_bill_attributes
    {
      amount: "120.45",
      customer_code: "C001",
      customer_name: "Yohannes Aregay Hailu",
      customer_phone: "0911000000",
      time: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
      description: "Food delivery",
      bill_reference: live_bill_reference,
      merchant_id: test_env_merchant_id,
      extras: { "source" => "ruby_live_smoke" }
    }
  end

  def live_bill_reference
    "ruby-smoke/#{Time.now.strftime("%Y%m%d%H%M%S")}-#{SecureRandom.hex(4)}"
  end

  def expect_success(result)
    expect(result).to be_a(Hash)
    expect(result["error"].to_s).to eq("")
  end

  def test_env_configured?
    test_env_merchant_id != "" && test_env_api_key != ""
  end

  def test_env_merchant_id
    ENV.fetch("WEBIRR_TEST_ENV_MERCHANT_ID", "").strip
  end

  def test_env_api_key
    ENV.fetch("WEBIRR_TEST_ENV_API_KEY", "").strip
  end
end
# rubocop:enable Metrics/BlockLength
