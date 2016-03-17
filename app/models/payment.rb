module Payment
  class << self
    def table_name_prefix
      'payment_'
    end

    def write_transaction(bt_result, page_id, member_id, existing_customer, save_customer=true)
      BraintreeTransactionBuilder.build(bt_result, page_id, member_id, existing_customer, save_customer)
    end

    def write_subscription(subscription_result, page_id, action_id, currency)
      if subscription_result.success?
        Payment::BraintreeSubscription.create({
          subscription_id:        subscription_result.subscription.id,
          amount:                 subscription_result.subscription.price,
          merchant_account_id:    subscription_result.subscription.merchant_account_id,
          action_id:              action_id,
          currency:               currency,
          page_id:                page_id
        })
      end
    end

    def write_customer(bt_customer, bt_payment_method, member_id, existing_customer)
      BraintreeCustomerBuilder.build(bt_customer, bt_payment_method, member_id, existing_customer)
    end

    def customer(email)
      customer = Payment::BraintreeCustomer.find_by(email: email)
      return customer if customer.present?
      member = Member.find_by(email: email)
      member.try(:customer)
    end
  end

  class BraintreeCustomerBuilder
    def self.build(bt_customer, bt_payment_method, member_id, existing_customer)
      new(bt_customer, bt_payment_method, member_id, existing_customer).build
    end

    def initialize(bt_customer, bt_payment_method, member_id, existing_customer)
      @bt_customer = bt_customer
      @bt_payment_method = Payment::BraintreePaymentMethodToken.find_or_create_by!(
          braintree_customer_id: @bt_customer.id,
          braintree_payment_method_token: bt_payment_method.token)
      @existing_customer = existing_customer
      @member_id = member_id
    end

    def build
      if @existing_customer.present?
        @existing_customer.update(customer_attrs)
      else
        Payment::BraintreeCustomer.create(customer_attrs)
      end
    end

    def customer_attrs
      card_attrs.merge({
        default_payment_method_token_id: @bt_payment_method.id,
        customer_id:      @bt_customer.id,
        member_id:        @member_id,
        email:            @bt_customer.email
      })
    end

    def card_attrs
      if @bt_payment_method.class == Braintree::CreditCard
        {
          card_type:        @bt_payment_method.card_type,
          card_bin:         @bt_payment_method.bin,
          cardholder_name:  @bt_payment_method.cardholder_name,
          card_debit:       @bt_payment_method.debit,
          card_last_4:      @bt_payment_method.last_4,
          card_unique_number_identifier: @bt_payment_method.unique_number_identifier
        }
      else
        {
          card_last_4: 'PYPL' # for now, assume PayPal if not CC
        }
      end
    end
  end

  class BraintreeTransactionBuilder
    #
    # Stores and associates a Braintree transaction as +Payment::BraintreeTransaction+. Builder will also
    # create or update an instance of +Payment::BraintreeCustomer+, if save_customer is passed
    #
    # === Options
    #
    # * +:bt_result+   - A Braintree::Transaction response object or a Braintree::Subscription response
    #                    (see https://developers.braintreepayments.com/reference/response/transaction/ruby)
    #                    or a Braintree::WebhookNotification
    # * +:page_id+     - the id of the Page to associate with the transaction record
    # * +:member_id+   - the member_id to associate with the customer record
    # * +:existing_customer+ - if passed, this customer is updated instead of creating a new one
    # * +:save_customer+     - optional, default true. whether to save the customer info too
    #
    #

    def self.build(bt_result, page_id, member_id, existing_customer, save_customer=true)
      new(bt_result, page_id, member_id, existing_customer, save_customer).build
    end

    def initialize(bt_result, page_id, member_id, existing_customer, save_customer=true)
      @bt_result = bt_result
      @page_id = page_id
      @member_id = member_id
      @existing_customer = existing_customer
      @save_customer = save_customer
    end

    def build
      return unless transaction.present?
      ::Payment::BraintreeTransaction.create(transaction_attrs)
      return unless successful? && @save_customer

      # it would be good to DRY this up and use CustomerBuilder, but we don't
      # have a Braintree::PaymentMethod to pass it :(
      if @existing_customer.present?
        pp "@EXISTING_CUSTOMER IS PRESENT", @existing_customer, customer_attrs
        @existing_customer.update(customer_attrs)
      else
        pp "CREATE CUSTOMER WITH", customer_attrs
        Payment::BraintreeCustomer.create(customer_attrs)
      end
    end

    private

    def transaction_attrs
      {
        transaction_id:          transaction.id,
        transaction_type:        transaction.type,
        payment_instrument_type: transaction.payment_instrument_type,
        amount:                  transaction.amount,
        transaction_created_at:  transaction.created_at,
        merchant_account_id:     transaction.merchant_account_id,
        processor_response_code: transaction.processor_response_code,
        currency:                transaction.currency_iso_code,
        # We won't have customer_id unless we store the customer in vault
        customer_id:             transaction.customer_details.id,
        status:                  status,
        # Payment method token should be changed to payment_method_token_id pointing to BraintreePaymentMethodTokens
        payment_method_token:    payment_method_token,
        page_id:                 @page_id
      }
    end

    def customer_attrs
      {
        # NOTE: we do NOT store card_unique_number_identifier because
        # that is only returned on Braintree::CreditCard, not on
        # Braintree::Transaction::CreditCardDetails
        card_type:        card.card_type,
        card_bin:         card.bin,
        cardholder_name:  card.cardholder_name,
        card_debit:       card.debit,
        card_last_4:      last_4,
        default_payment_method_token_id: @bt_payment_method.id,
        customer_id:      transaction.customer_details.id,
        email:            transaction.customer_details.email,
        member_id:        @member_id
      }
    end

    def transaction
      @bt_result.transaction || @bt_result.subscription.try(:transactions).try(:first)
    end

    def card
      transaction.credit_card_details
    end

    def status
      if successful?
        Payment::BraintreeTransaction.statuses[:success]
      else
        Payment::BraintreeTransaction.statuses[:failure]
      end
    end

    def successful?
      return @bt_result.success? if @bt_result.respond_to?(:success?)
      if @bt_result.is_a?(Braintree::WebhookNotification) && @bt_result.kind == 'subscription_charged_successfully'
        return true
      end
      false
    end

    def last_4
      transaction.payment_instrument_type == "paypal_account" ? 'PYPL' : card.last_4
    end

    def payment_method_token
      case transaction.payment_instrument_type
      when "credit_card"
        transaction.credit_card_details.try(:token)
      when "paypal_account"
        transaction.paypal_details.try(:token)
      else
        nil
      end
    end
  end
end

