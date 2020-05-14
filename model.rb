require 'sqlite3'
require 'bcrypt'

module Model

  $db = SQLite3::Database.new('db/stonks.db')
  $db.results_as_hash = true

  # Check the login credentials provided against database
  #
  # @param [String] username The username
  # @param [String] password The password
  #
  # @return [Integer] The ID of the user if true, else -1
  def check_login(username, password)

    results = $db.execute('SELECT * FROM users WHERE username = ?', username)
    p results
    if results == [] 
      return -1
    end

    password_digest = results[0]['password_digest']
    userid = results[0]['userid']

    if BCrypt::Password.new(password_digest) == password 
      return userid
    else
      return 0
    end
  end

  # Register new user in database
  #
  # @param [String] username The username
  # @param [String] password The password
  def register_user(username, password_digest)
    $db.execute('INSERT INTO users (username, password_digest) VALUES (?, ?)', username, password_digest)
  end

  # Get all the information from specified table
  #
  # @param [String] table The name of the table
  #
  # @return [Array] Array of all information from the table
  def get_all_data(table)
    return $db.execute('SELECT * FROM ' + table);
  end

  # Get all the user data from specified table
  #
  # @param [String] table The name of the table
  # @param [Integer] userid The ID of user to fetch information for
  #
  # @return [Array] All user information from that table
  def get_user_data(table, userid)
    return $db.execute('SELECT * FROM ' + table + ' WHERE userid = ?', userid)
  end

  # Creates a database entry for new stock
  #
  # @param [String] stockname The name of the stock to be created
  # @param [Integer] amount The amount of stock to be created
  def create_stock(stockname, amount)
    $db.execute('INSERT INTO stocks (stockname, amount) VALUES (?, ?)', stockname, amount)
  end

  # Get all the stock data from specified table
  #
  # @param [String] table The name of the table
  # @param [Integer] stockid The ID of the sock to fetch information for
  #
  # @return [Array] All stock information from table
  def get_stock_data(table, stockid)
    return $db.execute('SELECT * FROM ' + table + ' WHERE stockid = ?', stockid)
  end

  # Creates a listing of stock and from user specified
  #
  # @param [Integer] userid The ID of user selling stock
  # @param [Integer] stockid The ID of stock to be sold
  # @param [Integer] amount The amount of stock to be sold
  # @param [Integer] price The price of all the stock
  def post_selling(userid, stockid, amount, price)
    $db.execute('INSERT INTO relation_user_stock_sale (userid, stockid, amount, price) VALUES (?, ?, ?, ?)', userid, stockid, amount, price)
  end

  # Get all listings
  #
  # @return [Array] Array of all listings
  def get_all_listings()
    return $db.execute('SELECT relation_user_stock_sale.id, relation_user_stock_sale.amount, relation_user_stock_sale.price, relation_user_stock_sale.userid, users.username, stocks.stockname FROM ((relation_user_stock_sale INNER JOIN users ON relation_user_stock_sale.userid = users.userid) INNER JOIN stocks ON relation_user_stock_sale.stockid = stocks.stockid);')
  end

  # Get data for specific listing
  #
  # @param [Integer] listingid ID of the listing
  #
  # @return [Array] Array of information about single listing
  def get_listing_data(listingid)
    return $db.execute('SELECT * FROM relation_user_stock_sale WHERE id = ?', listingid)
  end

  # Deletes listing from database
  #
  # @param [Integer] listingid ID of listing to be deleted
  def delete_listing(listingid)
    $db.execute('DELETE FROM relation_user_stock_sale WHERE id=?', listingid)
  end

  # Add stock to specified user and remove from seller
  #
  # @param [Integer] userid ID of user buying stock
  # @param [Integer] sellerid ID of seller
  # @param [Integer] stockid ID of stock being sold
  # @param [Integer] amount Amount of stock being sold
  #
  # @return [Integer] -1 if false else 0
  def add_stock_to_user(userid, sellerid, stockid, amount)

    user_stock_relation = get_user_data('relation_user_stock', userid)
    seller_stock_relation = get_user_data('relation_user_stock', sellerid)

    seller_stock_relation.each do |relation|
      if relation['stockid'] == stockid
        if relation['amount'] - amount < 0
          return -1
        end
      end
    end

    user_has_stock = false
    user_stock_relation.each do |relation|
      if relation['stockid'] == stockid
        user_has_stock = true
        break
      end
    end

    if user_has_stock
      $db.execute('UPDATE relation_user_stock SET amount = amount + ? WHERE stockid = ? AND userid = ?', amount, stockid, userid)
    else
      $db.execute('INSERT INTO relation_user_stock (userid, stockid, amount) VALUES (?, ?, ?)', userid, stockid, amount)
    end

    $db.execute('UPDATE relation_user_stock SET amount = amount - ? WHERE stockid = ? AND userid = ?', amount, stockid, sellerid)
    return 0
  end

  # Get the stock of a single user
  #
  # @param [Integer] userid ID of user
  #
  # @return [Array] Contains all the data for users stocks
  def get_user_stocks(userid)
    return $db.execute('SELECT stocks.stockname, relation_user_stock.stockid, relation_user_stock.amount FROM relation_user_stock INNER JOIN stocks ON relation_user_stock.stockid = stocks.stockid WHERE userid=?', userid)
  end

  # Delete specified user from database
  #
  # @param [Integer] userid The ID of user to be deleted
  def delete_user(userid) 
    $db.execute('DELETE FROM users WHERE userid=?', userid)
  end
end
