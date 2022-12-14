require 'json'
require 'forwardable'
require 'ostruct'
require 'openssl'

module ProductBoard
  # This class is the main access point for all JIRA::Resource instances.
  #
  # The client must be initialized with an options hash containing
  # configuration options. The available options are:
  #
  #   :site               => 'http://localhost:2990',
  #   :context_path       => '/jira',
  #   :rest_base_path     => "/rest/api/2",
  #   :ssl_verify_mode    => OpenSSL::SSL::VERIFY_PEER,
  #   :ssl_version        => nil,
  #   :use_ssl            => true,
  #   :auth_type          => :basic (only),
  #   :proxy_address      => nil,
  #   :proxy_port         => nil,
  #   :proxy_username     => nil,
  #   :proxy_password     => nil,
  #   :use_cookies        => nil, (not supported)
  #   :additional_cookies => nil, (not supported)
  #   :default_headers    => {},
  #   :read_timeout       => nil,
  #   :http_debug         => false,
  #
  # See the JIRA::Base class methods for all of the available methods on these accessor
  # objects.

  class Client
    extend Forwardable

    # The OAuth::Consumer instance returned by the OauthClient
    #
    # The authenticated client instance returned by the respective client type
    # (Oauth, Basic)
    attr_accessor :consumer, :request_client, :http_debug, :cache

    # The configuration options for this client instance
    attr_reader :options

    def_delegators :@request_client, :init_access_token, :set_access_token, :set_request_token, :request_token,
                   :access_token, :authenticated?

    DEFINED_OPTIONS = [
      :site,
      :context_path,
      :rest_base_path,
      :ssl_verify_mode,
      :ssl_version,
      :use_ssl,
      :username,
      :password,
      :api_token,
      :auth_type,
      :proxy_address,
      :proxy_port,
      :proxy_username,
      :proxy_password,
      :use_cookies,
      :additional_cookies,
      :default_headers,
      :read_timeout,
      :http_debug,
      :shared_secret
    ].freeze

    DEFAULT_OPTIONS = {
      site: 'https://api.productboard.com',
      context_path: '/',
      rest_base_path: '',
      ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER,
      use_ssl: true,
      auth_type: :basic,
      http_debug: false,
      use_cookies: false,
      default_headers: {'X-Version' => '1'}
    }.freeze

    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge(options)
      @options = options
      @options[:rest_base_path] = @options[:context_path] + @options[:rest_base_path]

      unknown_options = options.keys.reject { |o| DEFINED_OPTIONS.include?(o) }
      raise ArgumentError, "Unknown option(s) given: #{unknown_options}" unless unknown_options.empty?

      case options[:auth_type]
      when :basic
        @request_client = HttpClient.new(@options)
      else
        raise ArgumentError, 'Options: ":auth_type" must be ":basic'
      end

      @http_debug = @options[:http_debug]

      @options.freeze

      @cache = OpenStruct.new
    end

    # API hook to Features resource
    def Features # :nodoc:
      ProductBoard::Resource::FeaturesFactory.new(self)
    end

    # API hook to Components resource
    def Components # :nodoc:
      ProductBoard::Resource::ComponentsFactory.new(self)
    end

    # API hook to Version resource
    def Version # :nodoc:
      ProductBoard::Resource::VersionFactory.new(self)
    end

    # HTTP methods without a body
    def delete(path, headers = {})
      request(:delete, path, nil, merge_default_headers(headers))
    end

    def get(path, headers = {})
      request(:get, path, nil, merge_default_headers(headers))
    end

    def head(path, headers = {})
      request(:head, path, nil, merge_default_headers(headers))
    end

    # HTTP methods with a body
    def post(path, body = '', headers = {})
      headers = { 'Content-Type' => 'application/json' }.merge(headers)
      request(:post, path, body, merge_default_headers(headers))
    end

    def post_multipart(path, file, headers = {})
      puts "post multipart: #{path} - [#{file}]" if @http_debug
      @request_client.request_multipart(path, file, headers)
    end

    def put(path, body = '', headers = {})
      headers = { 'Content-Type' => 'application/json' }.merge(headers)
      request(:put, path, body, merge_default_headers(headers))
    end

    # Sends the specified HTTP request to the REST API through the
    # appropriate method (oauth, basic).
    def request(http_method, path, body = '', headers = {})
      puts "#{http_method}: #{path} - [#{body}]" if @http_debug
      @request_client.request(http_method, path, body, headers)
    end

    # Stops sensitive client information from being displayed in logs
    def inspect
      "#<ProductBoard::Client:#{object_id}>"
    end

    protected

    def merge_default_headers(headers)
      { 'Accept' => 'application/json' }.merge(@options[:default_headers]).merge(headers)
    end
  end
end
