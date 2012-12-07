require 'spec_helper'
require 'rack/test'
require 'nokogiri'
require_relative '../lib/rspec_api_documentation/wurl_writer'

describe RspecApiDocumentation::WurlExample do
  describe '#transform_request_url_parameters' do
    let(:wurl_example) { RspecApiDocumentation::WurlExample.new(nil, RspecApiDocumentation::Configuration.new) }

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
      let(:wurl_example) { RspecApiDocumentation::WurlExample.new(stub_object, RspecApiDocumentation::Configuration.new) }

      it 'shows optional parameters that are not in the initial request string' do
        wurl_example.get_all_request_parameters(request_body_string, 'application/json').should == [
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
      let(:wurl_example) { RspecApiDocumentation::WurlExample.new(stub_object, RspecApiDocumentation::Configuration.new) }

      it 'shows optional parameters that are not in the initial request string' do
        wurl_example.get_all_request_parameters(request_body_string, 'application/html').should == [
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
      let(:wurl_example) { RspecApiDocumentation::WurlExample.new(stub_object, RspecApiDocumentation::Configuration.new) }

      it 'shows optional parameters that are not in the initial request string' do
        wurl_example.get_all_request_parameters(request_body_string, 'application/html').should == [
            {:key => 'param1[]', :value => '1', :not_required => true},
            {:key => 'param1[]', :value => '2', :not_required => true},
            {:key => 'param2', :value => '', :not_required => true}
        ]
      end
    end
  end

  describe "#mark_url_params_as_required!" do
    let(:url_params) { ["dataset_id"] }
    let(:all_params) {
      [
          {:name => "dataset_id", :description => "Shiny"},
          {:name => "unrelated_id", :description => "Not shiny"}
      ]
    }

    let(:wurl_example) { RspecApiDocumentation::WurlExample.new(nil, RspecApiDocumentation::Configuration.new) }

    before do
      wurl_example.mark_url_params_as_required!(url_params, all_params)
    end

    it "marks url params as required" do
      all_params[0][:required].should be_true
    end

    it "doesn't mark non-url parameters as required" do
      all_params[1][:required].should be_false
    end
  end

  describe "javascript fixture generation" do
    let(:configuration) { RspecApiDocumentation::Configuration.new }
    let(:metadata) do
      {
          :should_document => true,
          :parameters => [
              {:name => "foo", :description => "Foo!"},
              {:name => "bar", :description => "Bar!"}
          ],
          :route => '/something/:id',
          :requests => [
              {
                  :request_method => 'POST',
                  :request_path => '/something/7',
                  :request_headers => {"Header" => "value"},
                  :request_query_parameters => {"query" => "value"},
                  :request_body => "multi_value_param%5B%5D=value1&multi_value_param%5B%5D=value2&foo=bar",
                  :response_status => 200,
                  :response_status_text => "OK",
                  :response_headers => {"Header" => "value", "Foo" => "bar"},
                  :response_body => "body"
              }
          ]
      }
    end
    let(:group) { RSpec::Core::ExampleGroup.describe("test group") }
    let(:spec_example) { group.example("test example", metadata) }
    let(:example) { RspecApiDocumentation::Example.new(spec_example, configuration) }
    let(:wurl_example) { RspecApiDocumentation::WurlExample.new(example, configuration) }

    before do
      templates_path = File.expand_path('../templates/rspec_api_documentation', File.dirname(__FILE__))
      FakeFS::FileSystem.clone(templates_path)
    end

    it 'generates a fixture for post' do
      html = wurl_example.render
      fixture_path = File.expand_path('./javascripts/fixtures/wurl_post.html', File.dirname(__FILE__))
      FakeFS.deactivate!
      FileUtils.mkpath(File.dirname(fixture_path))
      File.open(fixture_path, 'w') do |f|
        f << Nokogiri::HTML::Document.parse(html).css(".container").to_s
      end
    end

    it "generates a fixture for get" do
      metadata[:requests][0][:request_method] = 'GET'
      metadata[:requests][0][:request_body] = ''
      html = wurl_example.render
      fixture_path = File.expand_path('./javascripts/fixtures/wurl_get.html', File.dirname(__FILE__))
      FakeFS.deactivate!
      FileUtils.mkpath(File.dirname(fixture_path))
      File.open(fixture_path, 'w') do |f|
        f << Nokogiri::HTML::Document.parse(html).css(".container").to_s
      end
    end
  end
end