require 'spec_helper'
require './lib/liquid_markup_seeder'
require 'rails_helper'

describe LiquidMarkupSeeder do
  subject { LiquidMarkupSeeder }

  describe '.name' do
    it 'parses filename for partial' do
      filename = '/foo/bar/_partial.liquid'

      expect( subject.parse_name(filename) ).to eq('Partial')
    end

    it 'parses filename for template' do
      filename = '/foo/bar/layout.liquid'

      expect( subject.parse_name(filename) ).to eq('Layout')
    end
  end

  describe '.meta' do
    it 'returns array with class and name' do
      partial = subject.title_and_class('/foo/bar/_partial.liquid')
      expect(partial).to eq( ['Partial', 'LiquidPartial'] )

      layout = subject.title_and_class('/foo/bar/layout.liquid')
      expect(layout).to eq( ['Layout', 'LiquidLayout'] )
    end
  end

  describe 'set_metadata_fields' do

    let(:view) { build :liquid_layout }
    let(:description) { "{% comment %} description: something sweet {%endcomment%}" }
    let(:experimental) { "{% comment %} experimental: true {% endcomment %}" }

    it 'sets experimental and description if they are included' do
      view.content = description + experimental
      subject.set_metadata_fields(view)
      expect(view.description).to eq "something sweet"
      expect(view.experimental).to eq true
    end

    it 'sets to nil if not included' do
      view.content = "something unrelated"
      subject.set_metadata_fields(view)
      expect(view.description).to eq nil
      expect(view.experimental).to eq false
    end

    it 'can set just experimental' do
      view.content = experimental
      subject.set_metadata_fields(view)
      expect(view.description).to eq nil
      expect(view.experimental).to eq true
    end

    it 'can set just description' do
      view.content = description
      subject.set_metadata_fields(view)
      expect(view.description).to eq "something sweet"
      expect(view.experimental).to eq false
    end

    it 'does not raise error when passed a liquid partial' do
      view = build :liquid_partial
      expect{ subject.set_metadata_fields(view) }.not_to raise_error
    end

  end

end
