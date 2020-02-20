require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative './model.rb'

enable :sessions

before do
  if ((((session[:userid] == nil) && (request.path != '/')) && (request.path != '/error')) && (request.path != '/login')) && (request.path != '/register')
    session[:error_message] = 'Not logged in'
    redirect('/error')
  end
end

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

  db = connect_to_db('db/stonks.db')

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
    user_stocks[index]['stockname'] = stock[index]['stockname']
    user_stocks[index]['amount'] = relation['amount']
    user_stocks[index]['stockid'] = relation['stockid']
  end

  slim(:'user/show', locals:{user_stocks:user_stocks})
end

post '/login' do
  username = params[:username]
  password = params[:password]

  #seconds = Time.now.to_i
  #
  #if session[:last_login_time] == nil
  #  session[:last_login_time] = []
  #end
  #session[:last_login_time].unshift(seconds)
  #
  #if session[:last_login_time].length >= 3
  #  value = session[:last_login_time][0] * 2 - session[:last_login_time][1] + session[:last_login_time][2] > 30
  #else
  #  session[:last_login_time].unshift(seconds)
  #end
  #
  #p session[:last_login_time]

  userid = check_login(username, password)

  if userid == -1 # No user found
    session[:error_message] = 'No user with that username'
    redirect('/error')
  elsif userid == 0 # Wrong password
    session[:error_message] = 'Wrong password'
    redirect('/error')
  else
    session[:userid] = userid
    redirect('/stocks')
  end
end

post '/register' do
  username = params[:username]
  password = params[:password]

  if password.length < 6
    session[:error_message] = 'Password too short'
    redirect('/error')
  elsif username.length < 4
    session[:error_message] = 'Username too short'
    redirect('/error')
  end


  db = connect_to_db('db/stonks.db')

  password_digest = BCrypt::Password.create(password)

  db.execute('INSERT INTO users (username, password_digest) VALUES (?, ?)', username, password_digest)

  redirect('/')
end

get '/logout' do
  session.destroy
  redirect('/')
end
