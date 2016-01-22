require 'byebug'                # optional, may be helpful
require 'open-uri'              # allows open('http://...') to return body
require 'cgi'                   # for escaping URIs
require 'nokogiri'              # XML parser
require 'active_model'          # for validations

class OracleOfBacon

  class InvalidError < RuntimeError ; end
  class NetworkError < RuntimeError ; end
  class InvalidKeyError < RuntimeError ; end

  attr_accessor :from, :to
  attr_reader :api_key, :response, :uri

  
  
  include ActiveModel::Validations
  validates_presence_of :from
  validates_presence_of :to
  validates_presence_of :api_key
  validate :from_does_not_equal_to

  def from_does_not_equal_to
    @errors.add('from', 'From cannot be the same as To') if @from == @to
  end

  def initialize(api_key='')
    @from = 'Kevin Bacon'
    @to = 'Kevin Bacon'
    @api_key = api_key
    @errors = ActiveModel::Errors.new(self)
    #38b99ce9ec87
  end

  def find_connections
    make_uri_from_arguments
    begin
      xml = URI.parse(uri).read
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
      Net::ProtocolError => e
      # convert all of these into a generic OracleOfBacon::NetworkError,
      #  but keep the original error message
      raise OracleOfBacon::NetworkError.new(e.message)
    end
    # your code here: create the OracleOfBacon::Response object
    @response = Response.new(xml)
  end

  def make_uri_from_arguments
    @uri = "http://oracleofbacon.org/cgi-bin/xml?p=#{@api_key}&a=#{CGI.escape(@from)}&b=#{CGI.escape(@to)}"
  end
      
  class Response
    attr_reader :type, :data
    # create a Response object from a string of XML markup.
    def initialize(xml)
      @doc = Nokogiri::XML(xml)
      parse_response
    end

    private

    def parse_response
      if ! @doc.xpath('/error').empty?
        parse_error_response
      elsif !@doc.xpath('/link').empty?
        parse_graph_response
      elsif !@doc.xpath('/spellcheck').empty?
        parse_spellcheck_response
      elsif !@doc.xpath('/other').empty?
        parse_unknown_response
      end
    end
    def parse_error_response
      @type = :error
      @data = 'Unauthorized access'
    end

    def parse_graph_response
        @type = :graph
        @data = []

        @doc.xpath('/link')[0].children.each do |node|
          @data << node.text unless node.text.strip.empty?
        end
    end

    def parse_spellcheck_response
       @type = :spellcheck
       @data = []

       @doc.xpath('/spellcheck')[0].children.each do |node|
         @data << node.text unless node.text.strip.empty?
       end
    end

    def parse_unknown_response
      @type = :unknown
      @data = 'unknown response type'
    end
  end
end

