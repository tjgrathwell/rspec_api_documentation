require 'spec_helper'
require_relative '../lib/rspec_api_documentation/wurl_writer'

describe RspecApiDocumentation::WurlExample do
  describe '#transform_request_url_parameters' do
    let(:wurl_example) { described_class.new(nil, RspecApiDocumentation::Configuration.new) }

    it 'does not interpret controller actions/namespaces as params' do
      wurl_example.transform_request_url_parameters('/admin').should be_empty
      wurl_example.transform_request_url_parameters('/admin/dashboard').should be_empty
    end

    it 'transforms the url params' do
      wurl_example.transform_request_url_parameters('/accounts/1/orders/2').should == [
          {:key => 'accounts', :value => '1'},
          {:key => 'orders', :value => '2'}
      ]
      wurl_example.transform_request_url_parameters('/admin/accounts/1/orders/2/blah').should == [
          {:key => 'accounts', :value => '1'},
          {:key => 'orders', :value => '2'}
      ]
    end

  end
end