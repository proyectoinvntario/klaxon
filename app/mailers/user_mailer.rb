require 'sendgrid-ruby'
include SendGrid

class UserMailer < ApplicationMailer
  layout 'user_mailer'

  def login_email(user: nil)
    token = LoginToken.create(user: user)
    @url = token_session_url(token: token)
    @user = user

    from = SendGrid::Email.new(email: 'no-reply@newsklaxon.org')
    to = SendGrid::Email.new(@user.email)
    subject = 'Log in to Klaxon'
    content = SendGrid::Content.new(type: 'text/plain', value: @url)
    mail = SendGrid::Mail.new(from, subject, to, content)

    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
    response = sg.client.mail._('send').post(request_body: mail.to_json)

    # mail(to: @user.email, subject: 'Log in to Klaxon')
  end

  def welcome_email(user: nil, invited_by: nil)
    token = LoginToken.create(user: user)
    @invited_by = invited_by
    @url = token_session_url(token: token)
    @user = user

    mail(to: @user.email, subject: 'Welcome to Klaxon!')
  end

end
