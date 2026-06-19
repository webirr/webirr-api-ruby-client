# Webirr
[![Gem Version](https://badge.fury.io/rb/webirr.svg)](https://badge.fury.io/rb/webirr)

Official Ruby gem for WeBirr Payment Gateway APIs

This gem provides convenient access to WeBirr Payment Gateway APIs from Ruby Applications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'webirr'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install webirr

## Usage

The library needs to be configured with a *merchant Id* & *API key*. You can get it by contacting [webirr.com](https://webirr.com)

> You can use this library for production or test environments. you will need to set is_test_env=true for test, and false for production apps when creating objects of class Webirr::Client

## Examples
### Creating a new Bill / Updating an existing Bill on WeBirr Servers

```rb
require 'webirr/bill'
require 'webirr/client'

# Create & Update Bill
def create_bill
    api_key = 'YOUR_API_KEY'
    merchant_id = 'YOUR_MERCHANT_ID'

    # client to use test environment
    webirr_client = Webirr::Client.new(api_key, true, merchant_id: merchant_id)

    bill = Webirr::Bill.new
    bill.amount = "120.45"
    bill.customer_code = "C001" # it can be email address or phone number if you dont have customer code
    bill.customer_name = "Yohannes Aregay Hailu"
    bill.time = "2022-09-06 14:20:26" # your bill time, always in this format
    bill.description = "Food delivery"
    bill.bill_reference = "ruby/2022/001" # your unique reference number
    bill.merchant_id = merchant_id

    puts "\nCreating Bill..."

    res = webirr_client.create_bill(bill)

    if (res["error"].to_s.empty?)
        # success
        payment_code = res["res"]  # returns paymentcode such as 429 723 975
        puts "\nPayment Code = #{payment_code}" # we may want to save payment code in local db.
    else
        # fail
        puts "\nerror: #{res["error"]}"
        puts "\nerrorCode: #{res["errorCode"]}" # can be used to handle specific business error such as ERROR_INVALID_INPUT_DUP_REF
    end

    #pp res

    # Update existing bill if it is not paid
    bill.amount = "278.00"
    bill.customer_name = 'John ruby'
    #bill.bill_reference = "WE CAN NOT CHANGE THIS"

    puts "\nUpdating Bill..."

    res = webirr_client.update_bill(bill)

    if (res["error"].to_s.empty?)
        # success
        puts "\nbill is updated successfully" #res.res will be 'OK'  no need to check here!
    else
        # fail
        puts "\nerror: #{res["error"]}"
        puts "\nerrorCode: #{res["errorCode"]}" # can be used to handle specific business error such as ERROR_INVALID_INPUT
    end
end

create_bill()

```


### Getting Payment status of an existing Bill from WeBirr Servers

```rb
require 'webirr/bill'
require 'webirr/client'

# Get Payment Status of Bill
def get_webirr_payment_status
    api_key = 'YOUR_API_KEY'
    merchant_id = 'YOUR_MERCHANT_ID'

    # client to use test environment
    webirr_client = Webirr::Client.new(api_key, true, merchant_id: merchant_id)

    payment_code = 'PAYMENT_CODE_YOU_SAVED_AFTER_CREATING_A_NEW_BILL'  # such as '141 263 782'

    puts "\nGetting Payment Status..."

    res = webirr_client.get_payment_status(payment_code)

    if (res["error"].to_s.empty?)
        # success
        if (res["res"]["status"] == 2)
          data =  res["res"]["data"]
          puts "\nbill is paid"
          puts "\nbill payment detail"
          puts "\nBank: #{data["bankID"]}"
          puts "\nBank Reference Number: #{data["paymentReference"]}"
          puts "\nAmount Paid: #{data["amount"]}"
        else
          puts "\nbill is pending payment"
        end
    else
        # fail
        puts "\nerror: #{res["error"]}"
        puts "\nerrorCode: #{res["errorCode"]}" # can be used to handle specific business error such as ERROR_INVALID_INPUT
    end

    #pp res
end

get_webirr_payment_status()

```

*Sample object returned from get_payment_status()*

```javascript
{
  error: null,
  res: {
    status: 2,
    data: {
      id: 111112347,
      paymentReference: '8G3303GHJN',      
      confirmed: true,
      confirmedTime: '2021-07-03 10:25:35',
      bankID: 'cbe_birr',
      time: '2021-07-03 10:25:33',
      amount: '4.60',
      wbcCode: '624 549 955'
    }
  },
  errorCode: null
}

```

### Getting a Bill / Listing Bills from WeBirr Servers

```rb
require 'webirr/bill'
require 'webirr/client'

# Get one bill by reference or payment code, and list bills by payment status.
def get_webirr_bills
    api_key = 'YOUR_API_KEY'
    merchant_id = 'YOUR_MERCHANT_ID'

    webirr_client = Webirr::Client.new(api_key, true, merchant_id: merchant_id)

    bill_reference = "ruby/2022/001"
    payment_code = 'PAYMENT_CODE_YOU_SAVED_AFTER_CREATING_A_NEW_BILL' # such as '141 263 782'

    puts "\nGetting Bill By Reference..."

    res = webirr_client.get_bill_by_reference(bill_reference)

    if (res["error"].to_s.empty?)
        # success
        puts "\nBill Found"
        puts res["res"]
    else
        # fail
        puts "\nerror: #{res["error"]}"
        puts "\nerrorCode: #{res["errorCode"]}" # can be used to handle specific business error such as ERROR_INVALID_INPUT
    end

    puts "\nGetting Bill By Payment Code..."

    res = webirr_client.get_bill_by_payment_code(payment_code)

    if (res["error"].to_s.empty?)
        # success
        puts "\nBill Found"
        puts res["res"]
    else
        # fail
        puts "\nerror: #{res["error"]}"
        puts "\nerrorCode: #{res["errorCode"]}"
    end

    puts "\nListing Bills..."

    payment_status = -1 # -1 all, 0 pending, 1 unconfirmed payment, 2 paid
    last_time_stamp = "20251231" # use "20251231235959" when you need time precision
    limit = 10

    res = webirr_client.get_bills(
      payment_status: payment_status,
      last_timestamp: last_time_stamp,
      limit: limit
    )

    if (res["error"].to_s.empty?)
        # success
        puts "\nBills returned: #{res["res"].length}"
        puts res["res"]
    else
        # fail
        puts "\nerror: #{res["error"]}"
        puts "\nerrorCode: #{res["errorCode"]}"
    end

    #pp res
end
get_webirr_bills()

```

### Getting Supported Banks for Checkout

```rb
require 'webirr/client'

def get_supported_banks
    api_key = 'YOUR_API_KEY'
    merchant_id = 'YOUR_MERCHANT_ID'

    webirr_client = Webirr::Client.new(api_key, true, merchant_id: merchant_id)

    puts "\nGetting Supported Banks..."

    res = webirr_client.get_supported_banks

    if (res["error"].to_s.empty?)
        res["res"].each do |bank|
            puts "#{bank["bankID"]} - #{bank["name"]}"
        end
        puts "Use only these merchant-specific banks when showing checkout payment instructions."
    else
        puts "\nerror: #{res["error"]}"
        puts "\nerrorCode: #{res["errorCode"]}"
    end
end

get_supported_banks()
```

Checkout pages should render bank-specific instructions only from `get_supported_banks`. Do not show a broad static bank list unless those banks are returned for the configured merchant.

### Getting list of Payments from WeBirr Servers

```rb
require 'webirr/client'

# Get list of Payments received after the last processed timestamp.
def get_webirr_payments
    api_key = 'YOUR_API_KEY'
    merchant_id = 'YOUR_MERCHANT_ID'

    webirr_client = Webirr::Client.new(api_key, true, merchant_id: merchant_id)

    last_time_stamp = "20251231" # use "20251231235959" when you need time precision
    limit = 10

    puts "\nRetrieving Payments..."

    res = webirr_client.get_payments(last_timestamp: last_time_stamp, limit: limit)

    if (res["error"].to_s.empty?)
        # success
        if (res["res"].length == 0)
            puts "\nNo new payments found."
        end
        res["res"].each do |payment|
            puts "\n-----------------------------"
            puts "\nPayment Status: #{payment["status"]}"
            puts "\nBank: #{payment["bankID"]}"
            puts "\nBank Reference Number: #{payment["paymentReference"]}"
            puts "\nAmount Paid: #{payment["amount"]}"
            puts "\nPayment Date: #{payment["paymentDate"]}"
            puts "\nUpdate Timestamp: #{payment["updateTimeStamp"]}"
        end
    else
        # fail
        puts "\nerror: #{res["error"]}"
        puts "\nerrorCode: #{res["errorCode"]}" # can be used to handle specific business error such as ERROR_INVALID_INPUT
    end
end

get_webirr_payments()

```

### Webhooks - Payment processing using Webhook Callbacks

```rb
require 'json'

# Webhook handler for processing payment updates from WeBirr.
# This endpoint should be hosted on a secure server with HTTPS enabled.
class Webhook
    # Handle incoming webhook POST requests.
    # Validate request method and check authentication using authKey from the query string.
    def handle_request(method, provided_auth_key, raw_payload)
        unless method.to_s.upcase == "POST"
            return json_response(405, "error" => "Method Not Allowed. POST required.")
        end

        unless authenticated?(provided_auth_key)
            return json_response(403, "error" => "Unauthorized access. Invalid authKey.")
        end

        if raw_payload.to_s.empty?
            return json_response(400, "error" => "Empty request body.")
        end

        payload = JSON.parse(raw_payload)
        payment = payload["data"] || payload

        if payment.nil? || payment.empty?
            return json_response(400, "error" => "Invalid payment data.")
        end

        # Process the payment asynchronously or enqueue it to a background worker.
        process_payment(payment)

        # Empty body with 200 OK is also acceptable.
        json_response(200, "success" => true, "message" => "Payment received and queued for processing")
    rescue JSON::ParserError
        json_response(400, "error" => "Invalid JSON format.")
    end

    private

    def authenticated?(provided_auth_key)
        # Prefer setting this from your application environment.
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
        puts "\nbill is paid" if payment["status"] == 2
        puts "\nbill payment is reversed" if payment["status"] == 3
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

# Once hosted, the webhook URL needs to be shared with WeBirr for configuration.
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To run live TestEnv smoke tests, set `WEBIRR_TEST_ENV_MERCHANT_ID` and `WEBIRR_TEST_ENV_API_KEY` before running the test task.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/webirr/webirr-api-ruby-client. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/webirr/webirr-api-ruby-client/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Webirr project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/webirr/webirr-api-ruby-client/blob/main/CODE_OF_CONDUCT.md).
