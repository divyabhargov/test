# app.rb
require 'sinatra'
require 'pry'
require_relative 'dashboard'

class HelloWorldApp < Sinatra::Base
	post '/run_pr' do
		return unless valid_slack_token?
		`./git_push.bash #{params[:text]}`
		content_type :json
		{ response_type: "in_channel", text: "Going to build PR #{params[:text]}. Monitor the status here - http://triggerpr.cfapps.io/dashboard/#{params[:text]}." }.to_json
	end

	get '/dashboard/:pr_no' do
		@concourse_url = "https://gpdb-dev.data.pivotal.ci"
		@pr_no = params[:pr_no]


		output = `./git_sha_from_pr_no.bash #{@pr_no}`
		begin
			sha = /commit (.*)/.match(output).captures.first
		rescue 
			@error = 'Error occured while retrieving details for the PR.'
		end
		
		if @error.nil?
			data = Dashboard.new([ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD']], @concourse_url, "dev:test_pr", "test-pr", 1, sha).data.first
			@status_of_jobs = {}


			data.values.map(&:status).uniq.each do |status|
				@status_of_jobs[status || 'yet_to_run or did_not_run'] = data.select{|k,v| v.status == status}
			end
			erb :dashboard
		else
			@error
		end
	end


	def valid_slack_token?
		params[:token] && params[:token] == ENV["SLACK_SLASH_COMMAND_TOKEN"]
	end

end
