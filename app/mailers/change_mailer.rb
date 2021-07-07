require 'net/http'
require 'uri'
require 'json'

class ChangeMailer < ApplicationMailer
  def page(user: nil, change: nil)
    @change = change
    @page = @change.after.page
    @user = user

    template = %{
      <html>
        <head><title></title></head>
        <body>
    
        <style>
        .diff {
          color: #000000;
          background-color: rgba(150,150,150, 0.1);
          font-family: Menlo, Monaco, Consolas, "Courier New", monospace;
          font-size: 90%;
        }
        .diff ul {
          list-style-type: none;
          -webkit-margin-before: 0;
          -webkit-margin-after: 0;
          -webkit-margin-start: 0;
          -webkit-margin-end: 0;
          -webkit-padding-start: 0;
        }
        .diff li {
          text-decoration: none !important;
          padding: 10px;
        }
        .diff del {
          text-decoration: none !important;
        }
        .diff .del {
          background-color: rgba(255,11,58, 0.2);
        }
        .diff .ins {
          background-color: rgba(0,255,0, 0.2);
        }
        
        .diff .ins ins {
          text-decoration: none !important;
        }
        </style>
        
        <div class="container">
            <div class="klax-app-name">
            Klaxon
          </div>
          <h3>Something Changed</h3>
        
          <p class="klax-lead"><b><%= @page.name %></b> changed. It has changed <b><%= @page.num_changes %></b> times since Klaxon started monitoring it on <b><%= @page.created_at.strftime("%A, %B %d, %Y") %>.</b></p>
        
          <p><a class="klax-button" style="margin-bottom: 50px;" href="<%= page_change_url(@change) %>">View this Snapshot</a></p>
        
          <p><%= link_to "View Source Page", @page.url, class: "klax-button", style: "margin-bottom: 50px;" %></p>
        
          <div class="diff">
            <%= raw Diffy::Diff.new(@change.before.match_text, @change.after.match_text, context: 2).to_s(:html_simple) %>
          </div>
        
        </div>        
    
        </body>
      </html>
    }.gsub(/^  /, '')

    content = ERB.new(template).result(binding)

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
