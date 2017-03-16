# frozen_string_literal: true
require 'rails_helper'

describe 'Emailing Targets' do
  let(:aws_client) { double(:aws_client, put_item: true) }

  before do
    allow(ChampaignQueue).to receive(:push)
    allow(Aws::DynamoDB::Client).to receive(:new) { aws_client }
    allow(aws_client).to receive(:put_item){ true }
  end

  describe 'POST#create' do
    let(:page) { create(:page, title: 'Foo Bar', slug: 'foo-bar') }
    let!(:plugin) { create(:email_target, page: page, email_from: 'origin@example.com') }

    let(:params) do
      {
        page: 'foo-bar',
        from_name: "Sender's Name",
        from_email: 'sender@example.com',
        to_name: "Target's Name",
        to_email: 'recipient@example.com',
        body: 'Body text',
        subject: 'Subject',
      }
    end

    before do
      post "/api/email_targets", params
    end

    it 'saves email to dynamodb' do
      expected_options = {
        table_name: "UserMailing",
        item: {
          MailingId: /foo-bar:\d*/,
          UserId: "sender@example.com",
          Body: "<p>Body text</p>",
          Subject: "Subject",
          ToName: "Target's Name",
          ToEmail: "recipient@example.com",
          FromName: "Sender's Name",
          FromEmail: "sender@example.com",
          SourceEmail: "origin@example.com",
        }
      }

      expect(aws_client).to have_received(:put_item).with(expected_options)
    end

    it 'creates an action and member' do
      expect(Action.count).to eq(1)

      expect(Action.first.member.attributes).to include({
        email: 'sender@example.com',
        first_name: "Sender's",
        last_name: 'Name'
      }.stringify_keys)
    end

    it 'posts action to queue' do
      expected_options = hash_including(
        {
          type: 'action',
          params: hash_including({
            page: 'foo-bar-petition',
            name: "Sender's Name",
          })
        }
      )

      expect(ChampaignQueue).to have_received(:push).with(expected_options)
    end
  end
end
