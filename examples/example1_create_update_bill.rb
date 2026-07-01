# frozen_string_literal: true

require "time"
require "webirr"

api_key = ENV.fetch("WEBIRR_TEST_ENV_API_KEY", "YOUR_API_KEY")
merchant_id = ENV.fetch("WEBIRR_TEST_ENV_MERCHANT_ID", "YOUR_MERCHANT_ID")

webirr_client = Webirr::Client.new(merchant_id, api_key, true)

bill = Webirr::Bill.new
bill.amount = "120.45"
bill.customer_code = "C001" # it can be email address or phone number if you dont have customer code
bill.customer_name = "Yohannes Aregay Hailu"
bill.customer_phone = "0911000000"
bill.time = "2022-09-06 14:20:26" # your bill time, always in this format
bill.description = "Food delivery"
bill.bill_reference = "ruby/example/#{Time.now.utc.strftime("%Y%m%d%H%M%S")}" # your unique reference number

puts "\nCreating Bill..."

res = webirr_client.create_bill(bill)

if res["error"].to_s.empty?
  payment_code = res["res"]
  puts "\nPayment Code = #{payment_code}" # we may want to save payment code in local db.
else
  puts "\nerror: #{res["error"]}"
  puts "\nerrorCode: #{res["errorCode"]}"
end

bill.amount = "278.00"
bill.customer_name = "John ruby"
# bill.bill_reference = "WE CAN NOT CHANGE THIS"

puts "\nUpdating Bill..."

res = webirr_client.update_bill(bill)

if res["error"].to_s.empty?
  puts "\nbill is updated successfully"
else
  puts "\nerror: #{res["error"]}"
  puts "\nerrorCode: #{res["errorCode"]}"
end
