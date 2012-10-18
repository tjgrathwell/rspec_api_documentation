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

  describe '#transform_request_body_parameters' do
    describe "with JSON parameters" do
      let(:stub_object) do
        Object.new.tap { |o|
          o.stub(:metadata).with(any_args) do
            { parameters:
              [
                { name: "param1", description: "a parameter" },
                { name: "param2", description: "a second parameter" },
                { name: "name", description: "some name" },
                { name: "paid", description: "paid?" },
                { name: "email", description: "the email" }
            ]
            }
          end
        }
      end
      let(:request_body_string) { '{"name":"Order 1","paid":true,"email":"email@example.com"}' }
      let(:wurl_example) { described_class.new(stub_object, RspecApiDocumentation::Configuration.new) }

      it 'shows optional parameters that are not in the initial request string' do
        wurl_example.transform_request_body_parameters(request_body_string, 'application/json').should == [
            {:key => 'name', :value => 'Order 1'},
            {:key => 'paid', :value => true},
            {:key => 'email', :value => 'email@example.com'},
            {:key => 'param1', :value => ''},
            {:key => 'param2', :value => ''}
        ]
      end
    end

    describe "with URL encoded parameters" do
      let(:stub_object) do
        Object.new.tap { |o|
          o.stub(:metadata).with(any_args) do
            { parameters:
              [
                { name: "param1", description: "a parameter" },
                { name: "param2", description: "a second parameter" },
                { name: "name", description: "some name" },
                { name: "paid", description: "paid?" },
                { name: "email", description: "the email" }
            ]
            }
          end
        }
      end
      let(:request_body_string) { 'name=Order%201&paid=true&email=email@example.com' }
      let(:wurl_example) { described_class.new(stub_object, RspecApiDocumentation::Configuration.new) }

      it 'shows optional parameters that are not in the initial request string' do
        wurl_example.transform_request_body_parameters(request_body_string, 'application/html').should == [
            {:key => 'name', :value => 'Order 1'},
            {:key => 'paid', :value => 'true'},
            {:key => 'email', :value => 'email@example.com'},
            {:key => 'param1', :value => ''},
            {:key => 'param2', :value => ''}
        ]
      end
    end

    describe "with URL encoded arrays" do
      let(:stub_object) do
        Object.new.tap { |o|
          stub(o).metadata.with_any_args do
            { parameters:
              [
                { name: "param1[]", description: "a parameter" },
                { name: "param2", description: "a second parameter" }
            ]
            }
          end
        }
      end
      let(:request_body_string) { 'param1%5B%5D=1&param1%5B%5D=2&param2=' }
      let(:wurl_example) { described_class.new(stub_object, RspecApiDocumentation::Configuration.new) }

      it 'shows optional parameters that are not in the initial request string' do
        wurl_example.transform_request_body_parameters(request_body_string, 'application/html').should == [
            {:key => 'param1[]', :value => '1'},
            {:key => 'param1[]', :value => '2'},
            {:key => 'param2', :value => ''}
        ]
      end
    end



  end
end
