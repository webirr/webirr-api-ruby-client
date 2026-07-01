# frozen_string_literal: true

require "webirr"

api_key = ENV.fetch("WEBIRR_TEST_ENV_API_KEY", "YOUR_API_KEY")
merchant_id = ENV.fetch("WEBIRR_TEST_ENV_MERCHANT_ID", "YOUR_MERCHANT_ID")

webirr_client = Webirr::Client.new(merchant_id, api_key, true)

bill_reference = ENV.fetch("WEBIRR_BILL_REFERENCE", "ruby/2022/001")
payment_code = ENV.fetch("WEBIRR_PAYMENT_CODE", "PAYMENT_CODE_YOU_SAVED_AFTER_CREATING_A_NEW_BILL")

puts "\nGetting Bill By Reference..."
res = webirr_client.get_bill_by_reference(bill_reference)

if res["error"].to_s.empty?
  puts "\nBill Found"
  puts res["res"]
else
  puts "\nerror: #{res["error"]}"
  puts "\nerrorCode: #{res["errorCode"]}"
end

puts "\nGetting Bill By Payment Code..."
res = webirr_client.get_bill_by_payment_code(payment_code)

if res["error"].to_s.empty?
  puts "\nBill Found"
  puts res["res"]
else
  puts "\nerror: #{res["error"]}"
  puts "\nerrorCode: #{res["errorCode"]}"
end

puts "\nListing Bills..."

payment_status = -1 # -1 all, 0 pending, 1 unconfirmed payment, 2 paid, 3 reversed
last_time_stamp = "20251231" # use "20251231235959" when you need time precision
limit = 10

res = webirr_client.get_bills(payment_status: payment_status, last_timestamp: last_time_stamp, limit: limit)

if res["error"].to_s.empty?
  puts "\nBills returned: #{res["res"].length}"
  puts res["res"]
else
  puts "\nerror: #{res["error"]}"
  puts "\nerrorCode: #{res["errorCode"]}"
end
