# app.rb
require 'sinatra'
require 'pry'

class HelloWorldApp < Sinatra::Base
	post '/run_pr' do
		return unless valid_slack_token?
		system("./git_push.bash #{params[:text]}")

		content_type :json
		{ response_type: "in_channel", text: "Going to build PR #{params[:text]}. See here - https://gpdb-dev.data.pivotal.ci/teams/main/pipelines/dev:test_pr." }.to_json
	end

	get '/pipeline_dashboard' do
		`PIPELINE_URL='https://gpdb-dev.data.pivotal.ci' RESOURCE_NAME='test-pr' ruby dashboard.rb pipeline_name=dev:test_pr number_of_commits=1`
	end


	def valid_slack_token?
		params[:token] && params[:token] == ENV["SLACK_SLASH_COMMAND_TOKEN"]
	end

end
