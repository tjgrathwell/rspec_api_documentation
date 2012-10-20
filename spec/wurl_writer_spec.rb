require 'spec_helper'
require_relative '../lib/rspec_api_documentation/wurl_writer'

describe RspecApiDocumentation::WurlExample do
  describe '#transform_request_url_parameters' do
    let(:wurl_example) { described_class.new(nil, RspecApiDocumentation::Configuration.new) }

    it 'does not interpret controller actions/namespaces as params' do
      wurl_example.transform_request_url_parameters('/admin', '/admin').should be_empty
      wurl_example.transform_request_url_parameters('/admin/dashboard', '/admin/dashboard').should be_empty
    end

    it 'transforms the url params' do
      wurl_example.transform_request_url_parameters('/admin/accounts/:account_id/orders/:order_id', '/accounts/1/orders/2').should == [
        {:key => 'account_id', :value => '1', :resource => 'accounts'},
        {:key => 'order_id', :value => '2', :resource => 'orders'}
      ]

      wurl_example.transform_request_url_parameters('/admin/accounts/:account_id/orders/:order_id/blah', '/accounts/1/orders/2/blah').should == [
          {:key => 'account_id', :value => '1', :resource => 'accounts'},
          {:key => 'order_id', :value => '2', :resource => 'orders'}
      ]
    end
  end

  describe '#transform_request_body_parameters' do
    describe "with JSON parameters" do
      let(:stub_object) do
        Object.new.tap { |o|
          o.stub(:metadata).with(any_args) do
            {
              parameters: [
                {name: "name", description: "some name", :required => true},
                {name: "paid", description: "paid?", :required => true},
                {name: "email", description: "the email", :required => true},
                {name: "param1", description: "a parameter"},
                {name: "param2", description: "a second parameter"}
              ]
            }
          end
        }
      end

      let(:request_body_string) { '{"name":"Order 1","paid":true,"email":"email@example.com"}' }
      let(:wurl_example) { described_class.new(stub_object, RspecApiDocumentation::Configuration.new) }

      it 'shows optional parameters that are not in the initial request string' do
        wurl_example.transform_request_body_parameters(request_body_string, 'application/json').should == [
          {:key => 'name', :value => 'Order 1', :not_required => false},
          {:key => 'paid', :value => true, :not_required => false},
          {:key => 'email', :value => 'email@example.com', :not_required => false},
          {:key => 'param1', :value => ''},
          {:key => 'param2', :value => ''}
        ]
      end
    end

    describe "with URL encoded parameters" do
      let(:stub_object) do
        Object.new.tap { |o|
          o.stub(:metadata).with(any_args) do
            {
              parameters: [
                {name: "param1", description: "a parameter"},
                {name: "param2", description: "a second parameter"},
                {name: "name", description: "some name"},
                {name: "paid", description: "paid?"},
                {name: "email", description: "the email"}
              ]
            }
          end
        }
      end

      let(:request_body_string) { 'name=Order%201&paid=true&email=email@example.com' }
      let(:wurl_example) { described_class.new(stub_object, RspecApiDocumentation::Configuration.new) }

      it 'shows optional parameters that are not in the initial request string' do
        wurl_example.transform_request_body_parameters(request_body_string, 'application/html').should == [
          {:key => 'name', :value => 'Order 1', :not_required => true},
          {:key => 'paid', :value => 'true', :not_required => true},
          {:key => 'email', :value => 'email@example.com', :not_required => true},
          {:key => 'param1', :value => ''},
          {:key => 'param2', :value => ''}
        ]
      end
    end

    describe "with URL encoded arrays" do
      let(:stub_object) do
        Object.new.tap { |o|
          o.stub(:metadata).with(any_args) do
            {
              parameters: [
                {name: "param1[]", description: "a parameter"},
                {name: "param2", description: "a second parameter"}
              ]
            }
          end
        }
      end

      let(:request_body_string) { 'param1%5B%5D=1&param1%5B%5D=2&param2=' }
      let(:wurl_example) { described_class.new(stub_object, RspecApiDocumentation::Configuration.new) }

      it 'shows optional parameters that are not in the initial request string' do
        wurl_example.transform_request_body_parameters(request_body_string, 'application/html').should == [
          {:key => 'param1[]', :value => '1', :not_required => true},
          {:key => 'param1[]', :value => '2', :not_required => true},
          {:key => 'param2', :value => '', :not_required => true}
        ]
      end
    end


  end
end
