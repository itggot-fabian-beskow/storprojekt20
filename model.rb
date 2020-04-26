require 'sqlite3'
require 'bcrypt'

module Model

  $db = SQLite3::Database.new('db/stonks.db')
  $db.results_as_hash = true

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

  def register_user(username, password_digest)
    $db.execute('INSERT INTO users (username, password_digest) VALUES (?, ?)', username, password_digest)
  end

  def get_all_data(table)
    return $db.execute('SELECT * FROM ' + table);
  end

  def get_user_data(table, userid)
    return $db.execute('SELECT * FROM ' + table + ' WHERE userid = ?', userid)
  end

  def create_stock(stockname, amount)
    $db.execute('INSERT INTO stocks (stockname, amount) VALUES (?, ?)', stockname, amount)
  end

  def get_stock_data(table, stockid)
    return $db.execute('SELECT * FROM ' + table + ' WHERE stockid = ?', stockid)
  end

  def post_selling(userid, stockid, amount, price)
    $db.execute('INSERT INTO relation_user_stock_sale (userid, stockid, amount, price) VALUES (?, ?, ?, ?)', userid, stockid, amount, price)
  end

  def get_all_listings()
    $db.execute('SELECT relation_user_stock_sale.id, relation_user_stock_sale.amount, relation_user_stock_sale.price, relation_user_stock_sale.userid, users.username, stocks.stockname FROM ((relation_user_stock_sale INNER JOIN users ON relation_user_stock_sale.userid = users.userid) INNER JOIN stocks ON relation_user_stock_sale.stockid = stocks.stockid);')
  end

  def get_listing_data(listingid)
    return $db.execute('SELECT * FROM relation_user_stock_sale WHERE id = ?', listingid)
  end

  def delete_listing(listingid)
    $db.execute('DELETE FROM relation_user_stock_sale WHERE id=?', listingid)
  end

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
  end

  def get_user_stocks(userid)
    return $db.execute('SELECT stocks.stockname, relation_user_stock.stockid, relation_user_stock.amount FROM relation_user_stock INNER JOIN stocks ON relation_user_stock.stockid = stocks.stockid WHERE userid=?', userid)
  end

  def delete_user(userid)
    $db.execute('DELETE FROM users WHERE userid=?', userid)
  end
end
