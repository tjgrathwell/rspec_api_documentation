require 'mustache'
require 'json'
require 'cgi'

module RspecApiDocumentation
  class WurlWriter
    attr_accessor :index, :configuration

    def initialize(index, configuration)
      self.index = index
      self.configuration = configuration
    end

    def self.write(index, configuration)
      writer = new(index, configuration)
      writer.write
    end

    def write
      File.open(configuration.docs_dir.join("index.html"), "w+") do |f|
        f.write WurlIndex.new(index, configuration).render
      end
      index.examples.each do |example|
        html_example = WurlExample.new(example, configuration)
        FileUtils.mkdir_p(configuration.docs_dir.join(html_example.dirname))
        File.open(configuration.docs_dir.join(html_example.dirname, html_example.filename), "w+") do |f|
          f.write html_example.render
        end
      end
    end
  end

  class WurlIndex < Mustache
    def initialize(index, configuration)
      @index = index
      @configuration = configuration
      self.template_path = configuration.template_path
    end

    def api_name
      @configuration.api_name
    end

    def sections
      IndexWriter.sections(examples, @configuration)
    end

    def url_prefix
      @configuration.url_prefix
    end

    def examples
      @index.examples.map { |example| WurlExample.new(example, @configuration) }
    end
  end

  class WurlExample < Mustache
    attr_accessor :example

    def initialize(example, configuration)
      @example = example
      @host = configuration.curl_host
      self.template_path = configuration.template_path
    end

    def method_missing(method, *args, &block)
      @example.send(method, *args, &block)
    end

    def respond_to?(method, include_private = false)
      super || @example.respond_to?(method, include_private)
    end

    def dirname
      resource_name.downcase.gsub(/\s+/, '_')
    end

    def filename
      basename = description.downcase.gsub(/\s+/, '_').gsub(/[^a-z_]/, '')
      "#{basename}.html"
    end

    def requests
      super.collect do |hash|
        hash[:request_headers_hash] = hash[:request_headers].collect { |k, v| {:name => k, :value => v} }
        hash[:request_headers_text] = format_hash(hash[:request_headers])
        hash[:request_path_no_query] = hash[:request_path].split('?').first
        hash[:request_query_parameters_text] = format_hash(hash[:request_query_parameters])
        hash[:request_query_parameters_hash] = hash[:request_query_parameters].collect { |k, v| {:name => k, :value => v} } if hash[:request_query_parameters].present?

        hash[:request_body_parameters_hash] = transform_request_body_parameters(hash[:request_body], hash[:request_headers]["Content-Type"])

        hash[:request_url_parameters_hash] = transform_request_url_parameters(hash[:request_path_no_query])

        hash[:response_headers_text] = format_hash(hash[:response_headers])
        hash[:response_status] = hash[:response_status].to_s + " " + Rack::Utils::HTTP_STATUS_CODES[hash[:response_status]].to_s
        if @host
          hash[:curl] = hash[:curl].output(@host) if hash[:curl].is_a? RspecApiDocumentation::Curl
        else
          hash[:curl] = nil
        end
        hash
      end
    end

    def transform_request_body_parameters(request_body_string, request_content_type)
      begin
        request_body = if request_content_type == "application/json"
                         JSON.parse(request_body_string)
                       else
                         parse_url_query_params(request_body_string)
                       end
      rescue Exception => e
        request_body = {}
      end

      if @example.metadata && @example.metadata[:parameters]
        @example.metadata[:parameters].each do |parameter|
          name = parameter[:name]
          if parameter[:scope]
            scope = parameter[:scope].to_s
          else
            scope = ''
          end

          unless contains_scoped_parameter(request_body, parameter)
            if scope != ""
              if request_body[scope] && request_body[scope][name].nil?
                request_body[scope][name] = ''
              end
            else
              if request_body[name].nil?
                request_body[name] = ''
              end
            end
          end
        end
      end

      request_body.map do | key, value |
        if !value.respond_to? :map
          { key: key, value: value }
        else
          required_values = value.map do | k, v |
            { k: k, v: v }
          end
          {
            key: key,
            value: required_values
          }
        end
      end
    end

    def contains_scoped_parameter(hash, parameter)
        scope = parameter[:scope]
        name = parameter[:name]

        hash[scope] && hash[scope][name]
    end


    def transform_request_url_parameters(request_url_string)
      params = request_url_string.scan(/([\w]+)\/([0-9]+)/)
      return [] unless params

      params.map do |param|
        { key: param[0], value: param[1] }
      end
    end

    def parse_url_query_params(url_params_string)
      flat = CGI.parse(url_params_string)
      nested = {}
      flat.each do |key, value|
        parts = key.split(/(\[|\])/)
        root_element = parts[0]
        child_element = parts[2]
        nested[root_element] ||= {}
        nested[root_element][child_element] = value.first
      end
      nested
    end

    def url_prefix
      configuration.url_prefix
    end

    private
    def format_hash(hash = {})
      return nil unless hash.present?
      hash.collect do |k, v|
        "#{k}: #{v}"
      end.join("\n")
    end
  end
end
