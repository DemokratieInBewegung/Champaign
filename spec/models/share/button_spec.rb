# frozen_string_literal: true
# == Schema Information
#
# Table name: share_buttons
#
#  id             :integer          not null, primary key
#  title          :string
#  url            :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  sp_id          :string
#  page_id        :integer
#  sp_type        :string
#  sp_button_html :string
#  analytics      :text
#

require 'rails_helper'

describe Share::Button do
  let(:button) { create :share_button }

  subject { button }

  it { is_expected.to be_valid }

  describe 'validation' do
    it 'is valid without a title' do
      button.title = nil
      expect(button).to be_valid
    end

    it 'is valid with a blank title' do
      button.title = ' '
      expect(button).to be_valid
    end

    it 'is invalid without a url' do
      button.url = nil
      expect(button).to be_invalid
    end

    it 'is invalid with a blank url' do
      button.url = ' '
      expect(button).to be_invalid
    end
  end
end
