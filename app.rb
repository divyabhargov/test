# app.rb
require 'sinatra'
require 'pry'

class HelloWorldApp < Sinatra::Base
  post '/run_pr' do
  	return unless valid_slack_token?
  	`git clone `
  	content_type :json
  	{ response_type: "in_channel", text: "Going to build PR #{params[:text]}. Hey Dhruv #{params}" }.to_json
  end

  get '/test' do
  	`which git`
  	`ssh-add -K ./pr`
  	`git clone git@github.com:divyabhargov/test.git`
  	`cd test`
  	`echo '3919' > pr.txt`
  	binding.pry
  	`git add .`
  	`git commit -m 'Update PR number to 3919`
  	`git remote add origin git@github.com:divyabhargov/test.git`
  	`git pull`
  	`git push origin master`
  	`cd ..`
  end

 #  get '/run_pr' do
	# 	'test'
	# # 	content_type :json
	# # 	return unless valid_slack_token?
	# # puts command_params
	# # { response_type: "in_channel", text: "Hey Dhruv" }
	# end

	def valid_slack_token?
	  params[:token] == ENV["SLACK_SLASH_COMMAND_TOKEN"]
	end

	# # Only allow a trusted parameter "white list" through.
	# def command_params
	# 	puts '----------------------------------------------------------------------------------'
	# 	puts params
	#   params.permit(:text, :token, :user_id, :response_url)
	# end
end
