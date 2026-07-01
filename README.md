# Webirr

Official Ruby gem for WeBirr Payment Gateway APIs

This gem provides convenient access to WeBirr Payment Gateway APIs from Ruby Applications.

Current release: `v2.1.1`

## Installation

The current Ruby SDK release can be installed directly from GitHub:

```ruby
# Use the latest GitHub release tag.
gem "webirr", git: "https://github.com/webirr/webirr-api-ruby-client.git", tag: "v2.1.1"
```

Then execute:

    $ bundle install

## Usage

The library needs to be configured with a *merchant Id* & *API key*. You can get it by contacting [webirr.com](https://webirr.com)

> You can use this library for production or test environments. You will need to set `is_test_env=true` for test, and false for production apps when creating objects of class `Webirr::Client`.

Examples assume the WeBirr TestEnv and read credentials from environment variables:

```bash
export WEBIRR_TEST_ENV_MERCHANT_ID="YOUR_TEST_MERCHANT_ID"
export WEBIRR_TEST_ENV_API_KEY="YOUR_TEST_API_KEY"
```

Create the client with merchant ID, API key, and environment once:

```rb
webirr_client = Webirr::Client.new(merchant_id, api_key, true)
```

The client automatically sets `bill.merchant_id` before sending bill create/update requests, so application code and examples should not set `bill.merchant_id` manually.

By default, TestEnv uses `https://api.webirr.dev` and production uses `https://api.webirr.com:8080`.

## Examples

### Creating a new Bill / Updating an existing Bill on WeBirr Servers

```rb
require "webirr"

# Create & Update Bill
def create_bill
    api_key = ENV.fetch("WEBIRR_TEST_ENV_API_KEY", "YOUR_API_KEY")
    merchant_id = ENV.fetch("WEBIRR_TEST_ENV_MERCHANT_ID", "YOUR_MERCHANT_ID")

    # client to use test environment
    webirr_client = Webirr::Client.new(merchant_id, api_key, true)

    bill = Webirr::Bill.new
    bill.amount = "120.45"
    bill.customer_code = "C001" # it can be email address or phone number if you dont have customer code
    bill.customer_name = "Yohannes Aregay Hailu"
    bill.customer_phone = "0911000000"
    bill.time = "2022-09-06 14:20:26" # your bill time, always in this format
    bill.description = "Food delivery"
    bill.bill_reference = "ruby/2022/001" # your unique reference number

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

    # Update existing bill if it is not paid
    bill.amount = "278.00"
    bill.customer_name = "John ruby"
    #bill.bill_reference = "WE CAN NOT CHANGE THIS"

    puts "\nUpdating Bill..."

    res = webirr_client.update_bill(bill)

    if (res["error"].to_s.empty?)
        # success
        puts "\nbill is updated successfully" # res["res"] will be "OK"; no need to check here!
    else
        # fail
        puts "\nerror: #{res["error"]}"
        puts "\nerrorCode: #{res["errorCode"]}" # can be used to handle specific business error such as ERROR_INVALID_INPUT
    end
end

create_bill()
```

### Getting a Bill / Listing Bills from WeBirr Servers

```rb
require "webirr"

# Get one bill by reference or payment code, and list bills by payment status.
def get_webirr_bills
    api_key = ENV.fetch("WEBIRR_TEST_ENV_API_KEY", "YOUR_API_KEY")
    merchant_id = ENV.fetch("WEBIRR_TEST_ENV_MERCHANT_ID", "YOUR_MERCHANT_ID")

    webirr_client = Webirr::Client.new(merchant_id, api_key, true)

    bill_reference = "ruby/2022/001"
    payment_code = "PAYMENT_CODE_YOU_SAVED_AFTER_CREATING_A_NEW_BILL" # such as "141 263 782"

    puts "\nGetting Bill By Reference..."

    res = webirr_client.get_bill_by_reference(bill_reference)

    if (res["error"].to_s.empty?)
        # success
        puts "\nBill Found"
        puts res["res"]
    else
        # fail
        puts "\nerror: #{res["error"]}"
        puts "\nerrorCode: #{res["errorCode"]}"
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

    payment_status = -1 # -1 all, 0 pending, 1 unconfirmed payment, 2 paid, 3 reversed
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
end

get_webirr_bills()
```

Timestamp cursors can be date-only (`yyyyMMdd`) or include time (`yyyyMMddHHmmss`). Use empty string only when you intentionally want all history from the beginning.

### Getting Supported Banks for Checkout

Use this endpoint to display only the banks and wallets configured for the merchant.

```rb
require "webirr"

def get_supported_banks
    api_key = ENV.fetch("WEBIRR_TEST_ENV_API_KEY", "YOUR_API_KEY")
    merchant_id = ENV.fetch("WEBIRR_TEST_ENV_MERCHANT_ID", "YOUR_MERCHANT_ID")

    webirr_client = Webirr::Client.new(merchant_id, api_key, true)

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

### Getting Payment status of an existing Bill from WeBirr Servers

```rb
require "webirr"

# Get Payment Status of Bill
def get_webirr_payment_status
    api_key = ENV.fetch("WEBIRR_TEST_ENV_API_KEY", "YOUR_API_KEY")
    merchant_id = ENV.fetch("WEBIRR_TEST_ENV_MERCHANT_ID", "YOUR_MERCHANT_ID")

    # client to use test environment
    webirr_client = Webirr::Client.new(merchant_id, api_key, true)

    payment_code = "PAYMENT_CODE_YOU_SAVED_AFTER_CREATING_A_NEW_BILL"  # such as "141 263 782"

    puts "\nGetting Payment Status..."

    res = webirr_client.get_payment_status(payment_code)

    if (res["error"].to_s.empty?)
        # success
        if Webirr::PaymentStatus.paid?(res["res"]["status"])
          data =  res["res"]["data"]
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
        # fail
        puts "\nerror: #{res["error"]}"
        puts "\nerrorCode: #{res["errorCode"]}"
    end
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
      status: 2,
      id: 111112347,
      paymentReference: "8G3303GHJN",
      confirmed: true,
      confirmedTime: "2021-07-03 10:25:35",
      bankID: "cbe_birr",
      paymentDate: "2021-07-03 10:25:33",
      time: "2021-07-03 10:25:33",
      amount: "4.60",
      wbcCode: "624 549 955",
      updateTimeStamp: "2021070310253300000"
    }
  },
  errorCode: null
}
```

### Deleting an existing Bill from WeBirr Servers (if it is not paid)

```rb
res = webirr_client.delete_bill("PAYMENT_CODE_YOU_SAVED_AFTER_CREATING_A_NEW_BILL")

if (res["error"].to_s.empty?)
    # success
    puts "\nbill is deleted successfully"
else
    # fail
    puts "\nerror: #{res["error"]}"
    puts "\nerrorCode: #{res["errorCode"]}"
end
```

### Payment status bulk polling

Use timestamp-based polling to synchronize paid or reversed payments in batch jobs.

```rb
last_time_stamp = "20251231" # use "20251231235959" when you need time precision
limit = 10

puts "\nRetrieving Payments..."

res = webirr_client.get_payments(last_timestamp: last_time_stamp, limit: limit)

if (res["error"].to_s.empty?)
    # success
    next_last_time_stamp = last_time_stamp

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

        if payment["updateTimeStamp"].to_s > next_last_time_stamp
            next_last_time_stamp = payment["updateTimeStamp"]
        end
    end

    # Persist next_last_time_stamp only after the batch is processed successfully.
    puts "\nNext cursor: #{next_last_time_stamp}"
else
    # fail
    puts "\nerror: #{res["error"]}"
    puts "\nerrorCode: #{res["errorCode"]}"
end
```

Do not use obsolete serial-number polling for new integrations.

### Webhooks - Payment processing using Webhook Callbacks

```rb
require "json"
require "webirr"

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
        puts "\nbill is paid" if Webirr::PaymentStatus.paid?(payment["status"])
        puts "\nbill payment is reversed" if Webirr::PaymentStatus.reversed?(payment["status"])
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

Webhook processing and polling should share the same local completion logic so that repeated callbacks, manual polling, or background reconciliation cannot complete the same merchant order twice.

## Payment Status Values

| Value | Constant | Meaning |
| --- | --- | --- |
| `0` | `Webirr::PaymentStatus::PENDING` | Pending / not paid |
| `1` | `Webirr::PaymentStatus::PAID_UNCONFIRMED` | Paid-unconfirmed / in progress |
| `2` | `Webirr::PaymentStatus::PAID` | Paid |
| `3` | `Webirr::PaymentStatus::REVERSED` | Reversed / canceled payment record |

### Getting basic Statistics

```rb
res = webirr_client.get_stat(date_from: "2021-01-01", date_to: "2021-12-31")

if (res["error"].to_s.empty?)
    puts "\nBills: #{res["res"]["NBills"]}"
    puts "\nPaid: #{res["res"]["NBillsPaid"]}"
    puts "\nAmount Paid: #{res["res"]["AmountPaid"]}"
else
    puts "\nerror: #{res["error"]}"
    puts "\nerrorCode: #{res["errorCode"]}"
end
```

## Runnable Examples

The `examples` directory contains runnable examples for:

- Creating and updating bills
- Single payment-status polling
- Deleting a bill
- Timestamp-based bulk payment polling
- Merchant statistics
- Webhook callback handling
- Getting and listing bills
- Getting merchant-supported banks

Run an example:

```bash
ruby examples/example1_create_update_bill.rb
```

Run tests:

```bash
bundle exec rspec
```

Live TestEnv smoke tests run only when these environment variables are set:

```bash
export WEBIRR_TEST_ENV_MERCHANT_ID="YOUR_TEST_MERCHANT_ID"
export WEBIRR_TEST_ENV_API_KEY="YOUR_TEST_API_KEY"
bundle exec rspec
```

## Error handling & retries

WeBirr business errors come back on HTTP 2xx responses in the parsed response hash as `res["error"]` / `res["errorCode"]`, such as invalid API key, duplicate bill reference, or validation errors. Everything else is a platform error from Faraday or the HTTP layer: network/DNS/TLS failures, timeouts, non-2xx HTTP, and invalid response bodies.

Retry only transient platform failures with exponential backoff and jitter: connection errors, timeouts, and HTTP 5xx / 429 / 408. Use `Webirr::TransientErrors.is_transient(error)` to apply that rule. Never retry other 4xx responses.

Create and read operations are safe to retry. `delete_bill` is also safe to retry, but a retry after it already succeeded returns an "invalid payment code" business error; treat that as already deleted.

```rb
begin
    res = webirr_client.create_bill(bill)
rescue StandardError => e
    if Webirr::TransientErrors.is_transient(e)
        # retry with backoff + jitter
    end
    # handle platform error
    return
end

if (res["error"].to_s.empty?)
    puts "\nPayment Code = #{res["res"]}"
else
    puts "\nerror: #{res["error"]}"
    puts "\nerrorCode: #{res["errorCode"]}"
end
```
