# frozen_string_literal: true

class Payment::Braintree::Result
  def initialize(result)
    @result = result
  end

  def payment_method_token
    if subscription?
      @result.subscription.payment_method_token
    elsif transaction?
      @result.transaction.credit_card_details.token
    end
  end

  def subscription?
    @result.subscription.present?
  end

  def transaction?
    @result.transaction.present?
  end
end

class PaymentController < ApplicationController
  skip_before_action :verify_authenticity_token

  def transaction
    builder = if recurring?
                client::Subscription.make_subscription(payment_options)
              else
                client::Transaction.make_transaction(transaction_options)
              end

    if builder.success?
      write_member_cookie(builder.action.member_id) unless builder.action.blank?
      id = recurring? ? { subscription_id: builder.subscription_id } : { transaction_id: builder.transaction_id }

      if store_in_vault?
        result = Payment::Braintree::Result.new(builder.result)

        existing_payment_methods = (cookies.signed[:payment_methods] || '').split(',')
        (existing_payment_methods << result.payment_method_token).uniq

        cookies.signed[:payment_methods] = {
          value: existing_payment_methods.join(','),
          expires: 1.year.from_now
        }
      end

      respond_to do |format|
        format.html { redirect_to follow_up_page_path(page) }
        format.json { render json: { success: true }.merge(id) }
      end
    else
      @errors = client::ErrorProcessing.new(builder.error_container, locale: locale).process
      @page = page
      respond_to do |format|
        format.html { render 'payment/donation_errors', layout: 'sumofus' }
        format.json { render json: { success: false, errors: @errors }, status: 422 }
      end
    end
  end

  private

  def recurring?
    @recurring ||= ActiveRecord::Type::Boolean.new.type_cast_from_user(params[:recurring])
  end

  def store_in_vault?
    @store_in_vault ||= ActiveRecord::Type::Boolean.new.type_cast_from_user(params[:store_in_vault]) || false
  end

  def page
    @page ||= Page.find(params[:page_id])
  end

  def locale
    page.try(:language).try(:code)
  end
end
