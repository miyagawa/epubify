require 'sinatra'
require 'readlists/anonymous'
require 'open-uri'
require 'open_uri_redirections'
require 'dropbox_sdk'

post '/' do
  if params[:url]
    if ENV['IFTTT_SECRET'] && ENV['IFTTT_SECRET'] != params[:secret]
      halt 401, 'error'
    end
    
    readlists = Readlists::Anonymous.create
    readlists.title = params[:title] if params[:title]
    readlists.description = params[:description] if params[:description]
    readlists << params[:url]
    
    file = open(readlists.share_url + "download/epub", allow_redirections: :safe)

    client = DropboxClient.new(ENV['DROPBOX_TOKEN'])
    client.put_file("/ifttt-#{Time.now.to_i}.epub", file)

    'OK'       
  else
    'No URL to render.'
  end
end
