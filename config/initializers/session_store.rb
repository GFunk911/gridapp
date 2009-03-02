# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_pegtest_session',
  :secret      => '88c5275dce60d572c99f74bb31a102eef11abaf451051cd15dead3aa0edbc76152958010962b7944c076d82910b39789a90e83503f03e4d7ddc5a982754ce1e2'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
