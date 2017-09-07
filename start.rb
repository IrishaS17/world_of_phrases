require 'sinatra'
require 'sqlite3'
require 'date'
require './Check'

set :sessions, true

configure do 
  @db = db_get
  @db.execute "CREATE TABLE IF NOT EXISTS `users` (
  `id`	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  `username`	TEXT NOT NULL UNIQUE,
  `password`	TEXT NOT NULL);
     
  CREATE TABLE IF NOT EXISTS `phrases` (
  `id`	INTEGER NOT NULL,
	`word`	TEXT NOT NULL,
	`id_user`	INTEGER NOT NULL,
	`flag`	INTEGER NOT NULL,
	`date_time`	TEXT NOT NULL);" 
end


get "/" do
  unless session[:current_user].nil?
     @username = session[:current_user] 
  end
  @db = db_get
  @result = @db.execute "SELECT GROUP_CONCAT (word, ' ')  AS word, id, flag FROM phrases GROUP BY id;"
  erb :index
end

get "/login" do
  redirect to("/") unless @user.nil?
  erb :login
end

get "/logout" do
  last_url = session[:last_url]
  session.delete(:current_user)
  redirect to last_url || '/'
end  

post "/login" do
  @username = params[:username]
  @password = params[:password]
  if check_unique_login(@username)
    @db = db_get
    @db.execute 'INSERT INTO users (username, password) VALUES (?, ?);', [@username, @password]
    session[:current_user] = @username
    redirect to("/")
  elsif check_password(@username, @password)
      session[:current_user] = @username
      redirect to("/")
  else
    @error = "This username is not available! Or incorrect password!"
    if @error
      erb :login
    end
  end
end

post "/add_word" do
@username = session[:current_user]
  @id = params[:id]
  @word = params[:word]
  @continue = params[:continue]
  a = check_and_save(@word, @continue, @username, @id)
  case a
      when 200
        redirect "/"
      when 404 
          @error = "Incorrect value or wait while someone else doesn't continue the phrase, because you can't continue the phrase after yourself! \n Perhaps your word contains a dot or more than one punctuation mark, which is unacceptable."
          erb :history
  end
end

get "/history" do
  @user = session[:current_user]
  redirect to("/login") if @user.nil?
  @id = params[:id]
  @db = db_get
  @result = @db.execute "SELECT p.flag, u.username, p.date_time, p.word FROM users u INNER JOIN phrases p ON p.id_user = u.id WHERE p.id = '#{@id}'"
  if @result.any?
      erb :history
  end
end

get "/new_phrase" do 
  @user = session[:current_user]
  redirect to("/login") if @user.nil?
  erb :new_phrase
end

post "/new_phrase" do
  redirect to("/login") if session[:current_user].nil?
  @username = session[:current_user]
  @word = params[:word]
  @continue = params[:continue]
  if check_and_save(@word, @continue, @username, 0)
      redirect "/"
  else
      @error = "Incorrect value! \n Perhaps your word contains a dot or more than one punctuation mark, which is unacceptable."
      if @error
          erb :new_phrase
      end
  end
end

get "/*" do
  redirect "/"
end