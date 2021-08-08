require 'dotenv/load'
require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader' if development?
require 'json'
require 'time'
require 'stringio'
require 'google/cloud/firestore'

enable :sessions
set session_secret: ENV.fetch('SESSION_SECRET') { |key| production? ? raise(KeyError, key) : 'asdf' }

before do
  session[:recent] ||= []
  session[:recent].delete('favicon.ico') # HACK
end

get '/' do
  erb :'index.html'
end

get '/new' do
  id = SecureRandom.urlsafe_base64(6)
  db.doc(id).set({ start: Time.now.iso8601, records: [] })

  cache_control :no_cache
  redirect "/#{id}"
end

get '/:id' do |id|
  session[:recent] << id unless session[:recent].include?(id)

  @id = id
  erb :'minutes.html'
end

post '/:id/sync' do |id|
  request.body.rewind
  minutes = JSON.parse(request.body.read)
  db.doc(id).set(minutes)

  status :ok
end

get '/:id/minutes.json' do |id|
  json db.doc(id).get.data
end

get '/:id/minutes.txt' do |id|
  minutes = db.doc(id).get.data
  start = Time.parse(minutes[:start])

  txt = StringIO.new
  minutes[:records].each do |minute|
    time = Time.parse(minute[:time])
    diff = (time - start).floor
    txt.puts "#{format_offset(diff)} #{minute[:text]}"
  end

  content_type 'text/plain'
  txt.string
end

helpers do
  def db
    @db ||= Google::Cloud::Firestore.new(project: 'minits').collection('minutes')
  end

  def format_offset(diff)
    "#{(diff / 60).to_s.rjust(2, '0')}:#{(diff % 60).to_s.rjust(2, '0')}"
  end
end
