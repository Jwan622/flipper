require 'helper'

RSpec.describe Flipper::UI::Actions::GroupsGate do
  let(:token) do
    if Rack::Protection::AuthenticityToken.respond_to?(:random_token)
      Rack::Protection::AuthenticityToken.random_token
    else
      'a'
    end
  end
  let(:session) do
    if Rack::Protection::AuthenticityToken.respond_to?(:random_token)
      { csrf: token }
    else
      { '_csrf_token' => token }
    end
  end

  describe 'GET /features/:feature/groups' do
    before do
      Flipper.register(:admins, &:admin?)
      get 'features/search/groups'
    end

    after do
      Flipper.unregister_groups
    end

    it 'responds with success' do
      expect(last_response.status).to be(200)
    end

    it 'renders add new group form' do
      expect(last_response.body).to include('<form action="/features/search/groups" method="post">')
    end
  end

  describe 'POST /features/:feature/groups' do
    let(:group_name) { 'admins' }

    before do
      Flipper.register(:admins, &:admin?)
    end

    after do
      Flipper.unregister_groups
    end

    context 'enabling a group' do
      before do
        post 'features/search/groups',
             { 'value' => group_name, 'operation' => 'enable', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'adds item to members' do
        expect(flipper[:search].groups_value).to include('admins')
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['Location']).to eq('/features/search')
      end

      context 'group name contains whitespace' do
        let(:group_name) { '  admins  ' }

        it 'adds item without whitespace' do
          expect(flipper[:search].groups_value).to include('admins')
        end
      end

      context 'for an unregistered group' do
        context 'unknown group name' do
          let(:group_name) { 'not_here' }

          # rubocop:disable Metrics/LineLength
          it 'redirects back to feature' do
            expect(last_response.status).to be(302)
            expect(last_response.headers['Location']).to eq('/features/search/groups?error=The+group+named+%22not_here%22+has+not+been+registered.')
          end
          # rubocop:enable Metrics/LineLength
        end

        context 'empty group name' do
          let(:group_name) { '' }

          # rubocop:disable Metrics/LineLength
          it 'redirects back to feature' do
            expect(last_response.status).to be(302)
            expect(last_response.headers['Location']).to eq('/features/search/groups?error=The+group+named+%22%22+has+not+been+registered.')
          end
          # rubocop:enable Metrics/LineLength
        end

        context 'nil group name' do
          let(:group_name) { nil }

          # rubocop:disable Metrics/LineLength
          it 'redirects back to feature' do
            expect(last_response.status).to be(302)
            expect(last_response.headers['Location']).to eq('/features/search/groups?error=The+group+named+%22%22+has+not+been+registered.')
          end
          # rubocop:enable Metrics/LineLength
        end
      end
    end

    context 'disabling a group' do
      let(:group_name) { 'admins' }

      before do
        flipper[:search].enable_group :admins
        post 'features/search/groups',
             { 'value' => group_name, 'operation' => 'disable', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'removes item from members' do
        expect(flipper[:search].groups_value).not_to include('admins')
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['Location']).to eq('/features/search')
      end

      context 'group name contains whitespace' do
        let(:group_name) { '  admins  ' }

        it 'removes item without whitespace' do
          expect(flipper[:search].groups_value).not_to include('admins')
        end
      end
    end
  end
end
