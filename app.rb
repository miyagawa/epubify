require 'sinatra'
require 'open-uri'
require 'open_uri_redirections'
require 'dropbox_sdk'
require 'uri'
require 'net/http'
require 'net/https'
require 'mail'

class ReadabilityArticle
  attr_reader :article_id
  
  def initialize(url)
    @url = url
    @article_id = query_article_id
  end

  def head_request(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    path_query = uri.path
    path_query += '?' + uri.query if uri.query
    http.head(path_query)
  end

  def query_article_id
    res = head_request('https://www.readability.com/api/content/v1/parser?' + URI.encode_www_form(url: @url))
    res['X-Article-Id']
  end

  def epub_url
    "https://www.readability.com/articles/#{article_id}/download/epub/"
  end

  def mobi_url
    loop do
      res = head_request "https://www.readability.com/articles/#{article_id}/download/kindle/"
      case res.code
      when "302", "301"
        puts "---> Kindle MOBI file generated"
        @mobi_url = res["Location"]
        break
      when "404"
        return
      else
        puts "---> Waiting for Kindle file generation"
        sleep 2
      end
    end

    @mobi_url
  end
end

module Delivery
  class Dropbox
    def initialize(token)
      @token = token
    end

    def deliver(article)
      file = open(article.epub_url, allow_redirections: :safe)

      client = DropboxClient.new(@token)
      client.put_file("/ifttt-#{Time.now.to_i}.epub", file)
    end
  end

  class Kindle
    def initialize(config)
      @config = MailConfig.new(config)
    end

    def deliver(article)
      build_mail(article.mobi_url).deliver
    end

    private

    def build_mail(url)
      mail = Mail.new
      mail.to = @config.mailto
      mail.from = @config.mailfrom
      mail.subject = 'IFTTT article'

      mail.text_part = Mail::Part.new do
        body 'New IFTTT Article'
      end

      mail.add_file filename: "ifttt-#{Time.now.to_i}.mobi", content: open(url, allow_redirections: :safe).read
      mail.delivery_method :smtp, @config.smtp_options

      mail
    end

    class MailConfig
      attr_accessor :mailto, :mailfrom, :smtp_server, :smtp_username, :smtp_password

      def initialize(args)
        args.each do |k, v|
          send("#{k}=", v)
        end
      end

      def smtp_options
        { address: address, port: port, domain: domain, user_name: user_name, password: password  }
      end

      def address
        smtp_server.split(':')[0]
      end

      def port
        smtp_server.split(':')[1] || 25
      end

      def domain
        smtp_username.split('@')[1]
      end

      def user_name
        smtp_username.split('@')[0]
      end

      def password
        smtp_password
      end
    end
  end
end

post '/' do
  if params[:url]
    if ENV['IFTTT_SECRET'] && ENV['IFTTT_SECRET'] != params[:secret]
      halt 401, 'error'
    end

    article = ReadabilityArticle.new(params[:url])

    unless article.article_id
      halt 400, 'Article not parsable'
    end

    puts "---> Article-Id: #{article.article_id}"

    if ENV['DROPBOX_TOKEN']
      Delivery::Dropbox.new(ENV['DROPBOX_TOKEN']).deliver(article)
    end

    if ENV['KINDLE_MAILTO']
      Delivery::Kindle.new(
        mailfrom: ENV['KINDLE_MAILFROM'],
        mailto: ENV['KINDLE_MAILTO'],
        smtp_server: ENV['SMTP_SERVER'],
        smtp_username: ENV['SMTP_USERNAME'],
        smtp_password: ENV['SMTP_PASSWORD'],
      ).deliver(article)
    end

    'OK'       
  else
    'No URL to render.'
  end
end
