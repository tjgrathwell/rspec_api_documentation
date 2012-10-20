require 'mustache'
require 'json'
require 'cgi'


module RspecApiDocumentation
  class KeyValueArray < Array
    def [](arg)
      tmp = find{ |e| e[:key] == arg }
      if tmp
        tmp[:value]
      else
        nil
      end
    end

    def []=(arg, val)
      tmp = find{ |e| e[:key] == arg }
      if tmp
        tmp[:value] = val
      else
        self << {:key => arg, :value => val}
      end
    end
  end

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

        hash[:request_url_parameters_hash] = transform_request_url_parameters(@example.metadata[:route], hash[:request_path_no_query])

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
                         KeyValueArray.new JSON.parse(request_body_string).map {|k,v| {:key => k, :value => v } }
                       else
                         parse_url_query_params(request_body_string)
                       end
      rescue Exception => e
        request_body = KeyValueArray.new
      end

      if @example.metadata && @example.metadata[:parameters]
        @example.metadata[:parameters].each do |parameter|
          name = parameter[:name]
          required = !!parameter[:required]
          scope = parameter[:scope].to_s || ''

          request_body.each do |element|
            if element[:key] == name
              element.merge!({:not_required => !required})
            end
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

      request_body
    end

    def contains_scoped_parameter(keyValArr, parameter)
        scope = parameter[:scope]
        name = parameter[:name]

        keyValArr[scope] && keyValArr[scope][name]
    end


    def transform_request_url_parameters(request_url_pattern, request_url_string)
      params_array = request_url_pattern.scan(/(\w+)\/:(\w+)/).zip(request_url_string.scan(/\d+/))

      params_array.map do |param|
        { :key => param[0].last, :value => param[1], :resource => param[0].first }
      end
    end

    def parse_url_query_params(url_params_string)
      flat = CGI.parse(url_params_string)
      nested = KeyValueArray.new
      flat.each do |key, value|
        value.each do |item|
          nested << { :key => key, :value => item }
        end
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
