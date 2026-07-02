# frozen_string_literal: true

require "webirr"

api_key = ENV.fetch("WEBIRR_TEST_ENV_API_KEY", "YOUR_API_KEY")
merchant_id = ENV.fetch("WEBIRR_TEST_ENV_MERCHANT_ID", "YOUR_MERCHANT_ID")

webirr_client = Webirr::Client.new(merchant_id, api_key, true)

last_time_stamp = "20251231" # use "20251231235959" when you need time precision
limit = 10

puts "\nRetrieving Payments..."

res = webirr_client.get_payments(last_timestamp: last_time_stamp, limit: limit)

if res["error"].to_s.empty?
  next_last_time_stamp = last_time_stamp

  puts "\nNo new payments found." if res["res"].empty?

  res["res"].each do |payment|
    puts "\n-----------------------------"
    puts "\nPayment Status: #{payment["status"]}"
    puts "\nBank: #{payment["bankID"]}"
    puts "\nBank Reference Number: #{payment["paymentReference"]}"
    puts "\nAmount Paid: #{payment["amount"]}"
    puts "\nPayment Date: #{payment["paymentDate"]}"
    puts "\nUpdate Timestamp: #{payment["updateTimeStamp"]}"

    next_last_time_stamp = payment["updateTimeStamp"] if payment["updateTimeStamp"].to_s > next_last_time_stamp
  end

  # Persist next_last_time_stamp only after the batch is processed successfully.
  puts "\nNext cursor: #{next_last_time_stamp}"
else
  puts "\nerror: #{res["error"]}"
  puts "\nerrorCode: #{res["errorCode"]}"
end
