require 'sqlite3'
require 'bcrypt'

def connect_to_db(db_name)
  db = SQLite3::Database.new(db_name)
  db.results_as_hash = true

  return db
end

def check_login(username, password)
  # MOVE TO MODEL
  db = connect_to_db('db/stonks.db')

  results = db.execute('SELECT * FROM users WHERE username = ?', username)
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
