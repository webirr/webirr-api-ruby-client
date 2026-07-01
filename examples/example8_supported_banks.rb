# frozen_string_literal: true

require "webirr"

api_key = ENV.fetch("WEBIRR_TEST_ENV_API_KEY", "YOUR_API_KEY")
merchant_id = ENV.fetch("WEBIRR_TEST_ENV_MERCHANT_ID", "YOUR_MERCHANT_ID")

webirr_client = Webirr::Client.new(merchant_id, api_key, true)

puts "\nGetting Supported Banks..."

res = webirr_client.get_supported_banks

if res["error"].to_s.empty?
  res["res"].each do |bank|
    puts "#{bank["bankID"]} - #{bank["name"]}"
  end
  puts "Use only these merchant-specific banks when showing checkout payment instructions."
else
  puts "\nerror: #{res["error"]}"
  puts "\nerrorCode: #{res["errorCode"]}"
end
