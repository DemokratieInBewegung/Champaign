# frozen_string_literal: true
class CallTool::Target
  include ActiveModel::Model

  attr_accessor :country_code, :postal_code, :phone_number, :name, :title

  validate  :country_is_valid
  validates :phone_number, presence: true
  validates :name,         presence: true

  def to_hash
    {
      country_code: country_code,
      postal_code: postal_code,
      phone_number: phone_number,
      name: name,
      title: title
    }
  end

  def country_name
    @country_name ||= ISO3166::Country[country_code]&.name
  end

  def country_name=(country_name)
    @country_name = country_name
    self.country_code = ISO3166::Country.find_country_by_name(country_name)&.alpha2
  end

  def ==(other)
    to_hash == other.to_hash
  end

  def id
    Digest::SHA1.hexdigest(to_hash.to_s)
  end

  private

  def country_is_valid
    if country_name.present? && country_code.blank?
      errors.add(:country, 'is invalid')
    end
  end
end
