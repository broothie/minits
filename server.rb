require 'dotenv/load'
require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader' if development?
require 'json'
require 'stringio'
require 'google/cloud/firestore'

db = Google::Cloud::Firestore.new(project: 'minits').collection('minits')

get '/' do
  id = SecureRandom.urlsafe_base64(6)
  db.doc(id).set({ minutes: [] })

  redirect "/#{id}"
end

get '/:id' do |id|
  @id = id
  erb :'minits.html'
end

get '/:id/minutes.json' do |id|
  json db.doc(id).get.data
end

post '/:id/sync.json' do |id|
  request.body.rewind
  minits = JSON.parse(request.body.read)
  db.doc(id).set(minits)

  status :ok
end

get '/:id/raw.txt' do |id|
  minits = db.doc(id).get.data
  start = Time.parse(minits[:start])

  txt = StringIO.new
  minits[:minutes].each do |minute|
    time = Time.parse(minute[:time])
    diff = (time - start).floor
    txt.puts "#{(diff / 60).to_s.rjust(2, '0')}:#{(diff % 60).to_s.rjust(2, '0')} #{minute[:text]}"
  end

  content_type 'text/plain'
  txt.string
end
