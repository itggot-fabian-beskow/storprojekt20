require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :session

get '/' do
  slim(:index)
end

get '/error' do
  'ERROR'
end

get '/stocks' do
  'STONKS'
end

post '/login' do
  username = params[:username]
  password = params[:password]

  db = SQLite3::Database.new('db/stonks.db')
  db.results_as_hash = true

  results = db.execute('SELECT password_digest FROM users WHERE username = ?', username)
  p results
  if results == [] 
    redirect('/error')
  end
  password_digest = results[0]['password_digest']
  if BCrypt::Password.new(password_digest) == password 
    redirect('/stocks')
  else
    redirect('/error')
  end

  #db.execute('INSERT INTO users (username, password_digest) VALUES (?, ?)', username, password_digest)
end

post '/register' do
  username = params[:username]
  password = params[:password]

  db = SQLite3::Database.new('db/stonks.db')
  db.results_as_hash = true

  password_digest = BCrypt::Password.create(password)

  db.execute('INSERT INTO users (username, password_digest) VALUES (?, ?)', username, password_digest)

  redirect('/')
end
