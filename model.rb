require 'sqlite3'
require 'bcrypt'

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

def get_stock_data(table, stockid)
  return $db.execute('SELECT * FROM ' + table + ' WHERE stockid = ?', stockid)
end
