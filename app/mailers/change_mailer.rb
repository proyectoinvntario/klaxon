require 'net/http'
require 'uri'
require 'json'

class ChangeMailer < ApplicationMailer
  def page(user: nil, change: nil)
    @change = change
    @page = @change.after.page
    @user = user
    @content = "Something Changed \n" + @page.name + " changed. It has changed " + @page.num_changes + " times since Klaxon started monitoring it on " + @page.created_at.strftime("%A, %B %d, %Y") + "\n View Source Page: " + @page.url + "\n"
    @content = @content + Diffy::Diff.new(@change.before.match_text, @change.after.match_text, context: 2).to_s()
       
    uri = URI.parse("https://api.sendgrid.com/v3/mail/send")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Authorization"] = "Bearer " + ENV['SENDGRID_API_KEY']
    request.body = JSON.dump({
      "personalizations" => [
        {
          "to" => [
            {
              "email" => @user.email,
              "name" => ""
            }
          ],
          "subject" => "#{@page.name} changed"
        }
      ],
      "content" => [
        {
          "type" => "text/plain",
          "value" => content
        }
      ],
      "from" => {
        "email" => "no-reply@newsklaxon.org",
        "name" => "Klaxon"
      },
      "reply_to" => {
        "email" => "no-reply@newsklaxon.org",
        "name" => "Klaxon"
      }
    })

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    puts "SENDGRID: request " + @user.email
    puts "SENDGRID: request " + ENV['SENDGRID_API_KEY']
    puts "SENDGRID: request " + @url 
    puts "SENDGRID: response " + response.code
    puts "SENDGRID: response " + response.body

    # mail(to: @user.email, subject: "#{@page.name} changed")
  end
end
