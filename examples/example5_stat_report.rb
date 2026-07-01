# frozen_string_literal: true

require "webirr"

api_key = ENV.fetch("WEBIRR_TEST_ENV_API_KEY", "YOUR_API_KEY")
merchant_id = ENV.fetch("WEBIRR_TEST_ENV_MERCHANT_ID", "YOUR_MERCHANT_ID")

webirr_client = Webirr::Client.new(merchant_id, api_key, true)

res = webirr_client.get_stat(date_from: "2021-01-01", date_to: "2021-12-31")

if res["error"].to_s.empty?
  puts "\nBills: #{res["res"]["NBills"]}"
  puts "\nPaid: #{res["res"]["NBillsPaid"]}"
  puts "\nAmount Paid: #{res["res"]["AmountPaid"]}"
else
  puts "\nerror: #{res["error"]}"
  puts "\nerrorCode: #{res["errorCode"]}"
end
