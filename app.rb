require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get '/' do
  slim(:index)
end

get '/error' do
  if session[:error_message] != nil
    error_message = session[:error_message]
    session[:error_message] = nil
    return error_message
  else 
    return 'Undefined Error'
  end
end

get '/stocks' do
  if session[:userid] == nil
    session[:error_message] = 'Not logged in'
    redirect('/error')
  end

  db = SQLite3::Database.new('db/stonks.db')
  db.results_as_hash = true

  results = db.execute('SELECT * FROM stocks')

  slim(:'stock/index', locals:{stock_list:results})
end

get '/my_page' do
  if session[:userid] == nil
    session[:error_message] = 'Not logged in'
    redirect('/error')
  end

  db = SQLite3::Database.new('db/stonks.db')
  db.results_as_hash = true

  user_stock_relation = db.execute('SELECT * FROM relation_user_stock WHERE userid = ?', session[:userid])

  user_stocks = [{}]

  user_stock_relation.each_with_index do |relation, index|
    stock = db.execute('SELECT * FROM stocks WHERE stockid = ?', relation['stockid']) 
    user_stocks[index]['stockname'] = stock[0]['stockname']
    user_stocks[index]['amount'] = relation['amount']
  end

  slim(:'user/show', locals:{user_stocks:user_stocks})
end

post '/login' do
  username = params[:username]
  password = params[:password]

  db = SQLite3::Database.new('db/stonks.db')
  db.results_as_hash = true

  results = db.execute('SELECT * FROM users WHERE username = ?', username)
  p results
  if results == [] 
    session[:error_message] = 'No user with that username'
    redirect('/error')
  end

  password_digest = results[0]['password_digest']
  userid = results[0]['userid']

  if BCrypt::Password.new(password_digest) == password 
    session[:userid] = userid
    redirect('/stocks')
  else
    session[:error_message] = 'Wrong password'
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
