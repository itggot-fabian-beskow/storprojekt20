require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative 'model'

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
  results = get_all_data('stocks')

  slim(:'stock/index', locals:{stock_list:results})
end

get '/stocks/new' do

  results = get_user_data('users', session[:userid])
  p results

  if results[0]['admin']
    return 'Hello!'
  else
    return 'get out'
  end

end

get '/sellings/' do
  sellings = get_all_data('relation_user_stock_sale')

  slim(:'sellings/show', locals:{listings:sellings})
end

get '/sellings/new/' do
end

get '/my_page' do

  user_stock_relation = get_user_data('relation_user_stock', session[:userid])

  user_stocks = [{}]

  user_stock_relation.each_with_index do |relation, index|
    stock = get_stock_data('stocks', relation['stockid'])
    user_stocks[index]['stockname'] = stock[index]['stockname']
    user_stocks[index]['amount'] = relation['amount']
    user_stocks[index]['stockid'] = relation['stockid']
  end

  slim(:'user/show', locals:{user_stocks:user_stocks})
end

post '/login' do
  username = params[:username]
  password = params[:password]

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


  password_digest = BCrypt::Password.create(password)

  register_user(username, password_digest)

  redirect('/')
end

get '/logout' do
  session.destroy
  redirect('/')
end
