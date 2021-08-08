require 'dotenv/load'
require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader' if development?
require 'json'
require 'stringio'

db = Google::Cloud::Firestore.new(project: 'minits').collection('sessions')

get '/' do
  id = SecureRandom.urlsafe_base64(6)
  db.doc(id).set({ minutes: [] })

  redirect "/#{id}"
end

get '/:id' do |id|
  @id = id
  erb :'index.html'
end

get '/:id/minutes.json' do |id|
  json db.doc(id).get.data
end

post '/:id/sync.json' do |id|
  request.body.rewind
  session = JSON.parse(request.body.read)
  db.doc(id).set(session, merge: true)

  status :ok
end

get '/:id/raw.txt' do |id|
  session = db.doc(id).get.data
  start = Time.parse(session[:start])

  txt = StringIO.new
  session[:minutes].each do |minute|
    time = Time.parse(minute[:time])
    diff = (time - start).floor
    txt.puts "#{(diff / 60).to_s.rjust(2, '0')}:#{(diff % 60).to_s.rjust(2, '0')} #{minute[:text]}"
  end

  content_type 'text/plain'
  txt.string
end
