# require 'sendgrid-ruby'
# include SendGrid
require 'net/http'
require 'uri'
require 'json'

class UserMailer < ApplicationMailer
  layout 'user_mailer'

  def login_email(user: nil)
    token = LoginToken.create(user: user)
    @url = token_session_url(token: token)
    @user = user

    # from = SendGrid::Email.new(email: 'no-reply@newsklaxon.org')
    # to = SendGrid::Email.new(@user.email)
    # subject = 'Log in to Klaxon'
    # content = SendGrid::Content.new(type: 'text/plain', value: @url)
    # mail = SendGrid::Mail.new(from, subject, to, content)

    # sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
    # response = sg.client.mail._('send').post(request_body: mail.to_json)

    # mail(to: @user.email, subject: 'Log in to Klaxon')

    uri = URI.parse("https://api.sendgrid.com/v3/mail/send")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    puts "SENDGRID: request " + @user.email
    puts "SENDGRID: request " + ENV['SENDGRID_API_KEY']
    puts "SENDGRID: request " + @url 
    request["Authorization"] = "Bearer <" + ENV['SENDGRID_API_KEY'] + ">"
    request.body = JSON.dump({
      "personalizations" => [
        {
          "to" => [
            {
              "email" => @user.email,
              "name" => ""
            }
          ],
          "subject" => "Log in to Klaxon"
        }
      ],
      "content" => [
        {
          "type" => "text/plain",
          "value" => @url
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

    puts "SENDGRID: response " + response.code
    puts "SENDGRID: response " + response.body
  end

  def welcome_email(user: nil, invited_by: nil)
    token = LoginToken.create(user: user)
    @invited_by = invited_by
    @url = token_session_url(token: token)
    @user = user

    mail(to: @user.email, subject: 'Welcome to Klaxon!')
  end

end
