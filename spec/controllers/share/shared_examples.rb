shared_examples "shares" do |share_class, service|
  let(:share){ instance_double(share_class, valid?: true) }
  let(:page)  { instance_double('Page', title: 'Foo', content: 'Bar', id: '1', to_param: '1' ) }

  before do
    allow(Page).to receive(:find).with('1'){ page }
  end

  describe 'GET#index' do
    before do
      allow(share_class).to receive(:where){ [share] }

      get :index, page_id: '1'
    end

    it 'finds campaign page' do
      expect(Page).to have_received(:find).with('1')
    end

    it 'gets shares' do
      expect(share_class).to have_received(:where).
        with(page_id: '1')
    end

    it 'assigns shares' do
      expect( assigns(:variations) ).to eq([share])
    end

    it 'renders share/inded' do
      expect( response ).to render_template('share/index')
    end
  end

  describe 'GET#new' do
    before do
      allow(share_class).to receive(:new){ share }

      get :new, page_id: '1'
    end

    it 'finds campaign page' do
      expect(Page).to have_received(:find).with('1')
    end

    it "instantiates instance of #{share_class} with default values" do
      expect(share_class).to have_received(:new).with(new_defaults)
    end

    it "assigns #{service}" do
      expect( assigns(:share) ).to eq(share)
    end

    it 'renders share/new' do
      expect( response ).to render_template('share/new')
    end
  end

  describe 'GET#edit' do
    before do
      allow(share_class).to receive(:find){ share }
      get :edit, page_id: '1', id: '2'
    end

    it 'finds campaign page' do
      expect(Page).to have_received(:find).with('1')
    end

    it 'assigns share' do
      expect( assigns(:share) ).to eq(share)
    end

    it 'renders share/edit' do
      expect( response ).to render_template('share/edit')
    end
  end

  describe 'PUT#update' do
    before do
      allow(ShareProgressVariantBuilder).to receive(:update){ share }

      put :update, page_id: 1, id: 2, "share_#{service}": params
    end

    it 'finds campaign page' do
      expect(Page).to have_received(:find).with('1')
    end

    it 'updates' do
      expect(ShareProgressVariantBuilder).to have_received(:update).
        with(params, {
        variant_type: service.to_sym,
        page: page,
        url: "http://test.host/pages/1",
        id: '2'
      })
    end

    it 'redirects to share index path' do
      expect( response ).to redirect_to("/pages/1/share/#{service.to_s.pluralize}")
    end
  end

  describe 'POST#create' do
    before do
      allow(ShareProgressVariantBuilder).to receive(:create){ share }

      post :create, page_id: 1, "share_#{service}": params
    end

    it 'finds campaign page' do
      expect(Page).to have_received(:find).with('1')
    end

    it 'creates' do
      expect(ShareProgressVariantBuilder).to have_received(:create).
        with(params, {
        variant_type: service.to_sym,
        page: page,
        url: "http://test.host/pages/1"
      })
    end

    it 'redirects to share index path' do
      expect( response ).to redirect_to("/pages/1/share/#{service.pluralize}")
    end
  end
end

