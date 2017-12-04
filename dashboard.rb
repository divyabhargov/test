require 'net/http'
require "uri"
require 'json'
require 'pry'
require 'colored'
require 'terminal-table'
require 'cgi'
require 'open-uri'
require 'net/https'

class Dashboard
	attr_reader :pipeline_url
	attr_reader :pipeline_name
	attr_reader :resource_name
	attr_reader :no_of_commits
	attr_reader :resource_shas
	attr_reader :basic_auth

	def initialize(basic_auth, pipeline_url, pipeline_name, resource_name, number_of_commits, resource_sha = nil)
		@basic_auth = basic_auth
		@pipeline_url = pipeline_url 
		@pipeline_name = pipeline_name
		@resource_name = resource_name
		@no_of_commits = number_of_commits || 1
		@resource_shas = [resource_sha] || get_sha_version_map(pipeline_name, number_of_commits).keys
	end

	def data
		resource_shas.map do |sha|
			get_job_status(pipeline_name, get_all_job_names(pipeline_name), sha)
		end
	end

	private

	def fetch_auth_token
		http_opts = {
		  http_basic_authentication: basic_auth,
		  ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
		}
		url = "#{pipeline_url}/api/v1/teams/main/auth/token"
		puts url
		puts http_opts
		token = JSON.parse(open(url, http_opts).read)
		"#{token['type']} #{token['value']}"
	end

	def http_get(path)
		uri = URI.parse("#{pipeline_url}/api/v1/#{path}")

	    http = Net::HTTP.new(uri.host, 80)
	    request = Net::HTTP::Get.new(uri.request_uri)
	    cookie1 = CGI::Cookie.new('ATC-Authorization', fetch_auth_token.to_s)
	    request['Cookie'] = cookie1.to_s
	    response = http.request(request)
	    JSON.parse(response.body)
	end

	def get_all_job_names(pipeline_name)
		jobs = http_get("teams/main/pipelines/#{pipeline_name}/jobs")
		jobs.map{|job| job['name']}
	end

	def get_sha_version_map(pipeline_name, limit = 500)
		versions = http_get("teams/main/pipelines/#{pipeline_name}/resources/#{resource_name}/versions?limit=#{limit}")
		sha_version_map = {}
		versions.each do |version|
			sha_version_map[version["version"]["ref"]] = version["id"]
		end
		sha_version_map
	end

	def get_job_status(pipeline_name, job_names, gpdb_src_sha)
		job_statuses = {}
		inputs_to = []

		concourse_check_version_id = get_sha_version_map(pipeline_name)[gpdb_src_sha]

		if concourse_check_version_id
			inputs_to = http_get("teams/main/pipelines/#{pipeline_name}/resources/#{resource_name}/versions/#{concourse_check_version_id}/input_to")
		end

		job_names.each do |job_name|
			job_statuses[job_name] = OpenStruct.new(inputs_to.select{|i| i['job_name'] == job_name}.first)
		end

		job_statuses
	end

	def get_output_version_for(pipeline_name, resource_name, output_from_job, gpdb_src_sha, limit=100)
		concourse_check_version_id = get_sha_version_map(pipeline_name)[gpdb_src_sha]
		if concourse_check_version_id
			inputs_to = http_get("teams/main/pipelines/#{pipeline_name}/resources/#{resource_name}/versions/#{concourse_check_version_id}/input_to")
		end
		job_generating_the_resource = inputs_to.select{|a| a['job_name'] == output_from_job}.last

		versions = http_get("teams/main/pipelines/#{pipeline_name}/resources/#{resource_name}/versions?limit=#{limit}")

		versions.each do |version|
			output_of = http_get("teams/main/pipelines/#{pipeline_name}/resources/#{resource_name}/versions/#{version['id']}/output_of")

			if output_of.size > 0
				output_build = output_of.select{|a| a['job_name']==output_from_job}.uniq.first
				if(output_build && output_build['url']) == job_generating_the_resource['url']
					return version
				end
			end
		end
		nil
	end

end
