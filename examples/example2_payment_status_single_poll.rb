# frozen_string_literal: true

require "webirr"

api_key = ENV.fetch("WEBIRR_TEST_ENV_API_KEY", "YOUR_API_KEY")
merchant_id = ENV.fetch("WEBIRR_TEST_ENV_MERCHANT_ID", "YOUR_MERCHANT_ID")
payment_code = ENV.fetch("WEBIRR_PAYMENT_CODE", "PAYMENT_CODE_YOU_SAVED_AFTER_CREATING_A_NEW_BILL")

webirr_client = Webirr::Client.new(merchant_id, api_key, true)

puts "\nGetting Payment Status..."

res = webirr_client.get_payment_status(payment_code)

if res["error"].to_s.empty?
  if Webirr::PaymentStatus.paid?(res["res"]["status"])
    data = res["res"]["data"]
    puts "\nbill is paid"
    puts "\nbill payment detail"
    puts "\nBank: #{data["bankID"]}"
    puts "\nBank Reference Number: #{data["paymentReference"]}"
    puts "\nAmount Paid: #{data["amount"]}"
    puts "\nPayment Date: #{data["paymentDate"] || data["time"]}"
  else
    puts "\nbill is pending payment"
  end
else
  puts "\nerror: #{res["error"]}"
  puts "\nerrorCode: #{res["errorCode"]}"
end
