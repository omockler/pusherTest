require 'sinatra'

class App < Sinatra::Base
	require 'bundler/setup'
	Bundler.require()

	include Mongo
	enable :sessions
	configure do
	  set :mongo_db, Mongo::MongoClient.from_uri.db["messages"]
	end
	
	Pusher.url = "http://#{ENV['APP_KEY']}:#{ENV["APP_SECRET"]}@api.pusherapp.com/apps/#{ENV['APP_ID']}"

	helpers do
		def user_id
			session[:user_id]
		end

		def authenticate!
			redirect '/set-session' unless user_id
		end
	end

	get '/' do
		authenticate!
		haml :index
	end

	post '/pusher/auth' do
		authenticate!
		content_type :json
		params[:channel_name] =~ /private-user-(\d{1})$/

		halt 403, "Forbidden" unless $1 == user_id
		Pusher[params[:channel_name]].authenticate(params[:socket_id]).to_json
	end

	get '/messages' do
		authenticate!
		content_type :json
		settings.mongo_db.find({user_id: user_id}).to_a.map do |m| 
			m["_id"] = m["_id"].to_s
			m
		end.to_json
	end

	get '/set-session' do
		haml :set_session
	end

	post '/set-session' do
		session[:user_id] = params[:user_id]
		redirect '/'
	end

	get '/post-message?' do
		message = {message: params[:message], read: false, dissmissed: false}
		
		if params[:all]
			(1..3).each do |i|
				local_message = message.clone
				local_message[:user_id] = i
				local_message[:_id] = settings.mongo_db.insert local_message
				Pusher.trigger("private-user-#{i}", "my_event", local_message)
			end
		elsif params[:user_id]
			message[:user_id] = params[:user_id]
			message[:_id] = settings.mongo_db.insert message
			Pusher.trigger("private-user-#{params[:user_id]}", "my_event", message)
		else
			halt 400, "Specify recipients" unless channel
		end
		"Success"
	end

	post '/mark-read' do
		authenticate!
		messages = settings.mongo_db.find({user_id: user_id, read: false}).to_a
		messages.each do |m|
			settings.mongo_db.remove {_id: m["_id"]}
		end
		"Success"
	end

	post '/dismiss-message/:message_id' do
		authenticate!
		message_id = BSON::ObjectId.from_string(params[:message_id])
		message = settings.mongo_db.find_one(_id: message_id)
		halt 400, "Not a valid message id" unless message["user_id"] == user_id
		settings.mongo_db.remove({_id: message_id})
		"Success"
	end
end
