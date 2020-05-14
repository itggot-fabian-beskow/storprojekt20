require 'sinatra' 
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative 'model'
include Model

enable :sessions

before do
  if ((((session[:userid] == nil) && (request.path != '/')) && (request.path != '/error')) && (request.path != '/login')) && (request.path != '/register')
    session[:error_message] = 'Not logged in'
    redirect('/error')
  end
end

# Display landing and login page
#
get '/' do
  if session[:userid] != nil
    redirect('/stocks/')
  end
  slim(:index)
end

# Displays an error message
#
get '/error' do
  if session[:error_message] != nil
    error_message = session[:error_message]
    session[:error_message] = nil
  else 
    error_message = 'Undefined Error'
  end
  slim(:'/error', locals:{message:error_message})
end

# Displays all the stocks
#
get '/stocks/' do
  results = get_all_data('stocks')

  slim(:'/stock/index', locals:{stock_list:results})
end

# Creates a new stock and redirects to '/stocks/'. Only for admins
#
# @param [String] stockname The name of the stock to be created
# @param [Integer] amount The amount of the stock to be created
#
# @see Model#create_stock
post '/stocks' do
  # Check if admin
  results = get_user_data('users', session[:userid])
  if results[0]['privilege'] > 0
    create_stock(params["stockname"], params["amount"])
    redirect('/stocks/')
  else
    session[:error_message] = "Only admins can create stock"
    redirect('/error')
  end
end

# Displays stock creating form for administrators
#
get '/stocks/new' do

  # check if admin
  results = get_user_data('users', session[:userid])
  if results[0]['privilege'] > 0
    slim(:'/stock/new')
  else
    session[:error_message] = 'Administrator only'
    redirect('/error')
  end
end

# Display all current listings
#
get '/sellings/' do
  #sellings = get_all_data('relation_user_stock_sale')
  sellings = get_all_listings()

  slim(:'selling/show', locals:{listings:sellings})
end

# Create a new listing for user and redirects to '/sellings'
#
# @param [Integer] stockid ID of the stock to be sold
# @param [Integer] amount Amount of the stock to be sold
# @param [Integer] price Price of the whole sale
#
# @see Model#post_selling
post '/sellings' do
  selling_stockid = params[:stockid].to_i
  selling_amount = params[:amount].to_i
  selling_price = params[:price].to_i

  if selling_stockid == nil || selling_stockid < 1
    session['error_message'] = 'Invalid stock ID'
    redirect('/error')
  elsif selling_amount == nil || selling_amount < 1
    session['error_message'] = 'Invalid selling amount'
    redirect('/error')
  elsif selling_price == nil || selling_price < 1
    session['error_message'] = 'Invalid selling price'
    redirect('/error')
  end

  user_stock_relation = get_user_data('relation_user_stock', session[:userid])
  # Check if user has enough of stock
  
  user_stock_relation.each do |relation|
    if relation['stockid'] == selling_stockid
      if relation['amount'] < selling_amount
        session[:error_message] = 'Not enough stock!'
        redirect('/error')
      end
    end
  end

  # post selling
  post_selling(session[:userid], selling_stockid, selling_amount, selling_price)

  redirect('/sellings/')
end

# Deletes or buys a listing depending on user and redirects to '/sellings/'
#
# @param [Integer] :listingid ID of listing to be deleted
post '/sellings/:listingid/delete' do
  listingid = params[:listingid]
  listing_data = get_listing_data(listingid)[0]

  if session[:userid].to_i == listing_data["userid"]
    delete_listing(listingid)
    redirect('/sellings/')
  else
    result = add_stock_to_user(session[:userid], listing_data['userid'], listing_data['stockid'], listing_data['amount'])

    delete_listing(listingid)

    if result == -1
      session[:error_message] = 'Seller does not have enough stock, listing deleted.'
      redirect('/error')
    end

    redirect('/sellings/')
  end
end

# Shows user profile
# 
# @param [Integer] :userid The ID of the user to be shown
get '/users/:userid' do

  if params[:userid].to_i != session[:userid].to_i
    results = get_user_data('users', session[:userid])
    if results[0]['privilege'] == 0
      session[:error_message] = 'Only administrators can view others profiles'
      redirect('/error')
    end
  end
  
  user_stocks = get_user_stocks(params[:userid])
  user_info = get_user_data('users', params[:userid])
  if user_info == []
    session[:error_message] = 'User does not exist'
    redirect('/error')
  end
  slim(:'user/show', locals:{user_stocks:user_stocks, userid:params[:userid]})
end

# Deletes a user and redirects to the landing page, '/'
#
# @param [Integer] :userid The ID of the user to be deleted
#
# @see Model#delete_user
post '/users/:userid/delete' do
  if params[:userid].to_i != session[:userid].to_i
    results = get_user_data('users', session[:userid])
    if results[0]['privilege'] == 0
      session[:error_message] = 'Only administrators can delete others profiles'
      redirect('/error')
    end
  end

  delete_user(params[:userid])
  session.destroy

  redirect('/')
end

# Attempts login, updates the session and redirects to '/stocks/' on success
# 
# @param [String] username The username
# @param [String] password The password
# 
# @see Model#check_login
post '/login' do
  username = params[:username]
  password = params[:password]

  # Login security
  if session[:login_attempts] == nil
    session[:login_attempts] = 1
  else
    session[:login_attempts] += 1
  end

  if session[:login_attempts] > 3
    session[:lockout_time] = Time.now.to_i
    session[:login_attempts] = 0
  end

  if session[:lockout_time] != nil
    if Time.now.to_i - session[:lockout_time] < 30
      session[:error_message] = 'Too many login attempts!'
      redirect('/error')
    else
      session[:lockout_time] = nil
    end
  end

  userid = check_login(username, password)

  if userid == -1 # No user found
    session[:error_message] = 'No user with that username'
    redirect('/error')
  elsif userid == 0 # Wrong password
    session[:error_message] = 'Wrong password'
    redirect('/error')
  else
    session[:userid] = userid
    redirect('/stocks/')
  end
end

# Attempts user registration and redirects back to login page
# 
# @param [String] username The username
# @param [String] password The password
# 
# @see Model#register_user
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

# Destroys the session and redirects to landing page
get '/logout/' do
  session.destroy
  redirect('/')
end
