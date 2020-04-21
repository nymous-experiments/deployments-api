require 'json'

require 'sinatra'
require 'octokit'

GITHUB_TOKEN = ENV["GITHUB_TOKEN"]
@client = Octokit::Client.new(access_token: GITHUB_TOKEN)

post '/event_handler' do
  payload = JSON.parse(params[:payload])

  case request.env['HTTP_X_GITHUB_EVENT']
  when "pull_request"
    if payload["action"] == "closed" && payload["pull_request"]["merged"]
      start_deployment(payload["pull_request"])
    end
  when "deployment"
    process_deployment(payload)
  when "deployment_status"
    update_deployment_status(payload)
  end
end

def start_deployment(pull_request)
  user = pull_request["user"]["login"]
  payload = JSON.generate({environment: "production", deploy_user: user})
  @client.create_deployment(
    pull_request['head']['repo']['full_name'],
    pull_request['head']['sha'],
    {:payload => payload, :description => "Deploying my sweet branch"}
  )
end

def process_deployment(payload)
  payload = JSON.parse(payload['payload'])
  # you can send this information to your chat room, monitor, pager, etc.
  puts "Processing '#{payload['description']}' for #{payload['deploy_user']} to #{payload['environment']}"
  sleep 15 # simulate work
  @client.create_deployment_status("repos/#{payload['repository']['full_name']}/deployments/#{payload['id']}", 'pending')
  sleep 15 # simulate work
  @client.create_deployment_status("repos/#{payload['repository']['full_name']}/deployments/#{payload['id']}", 'success')
end

def update_deployment_status(payload)
  puts "Deployment status for #{payload['id']} is #{payload['state']}"
end
