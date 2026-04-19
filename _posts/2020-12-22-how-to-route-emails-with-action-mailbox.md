---
layout: post
title: How to Route Emails with Action Mailbox
date: '2020-12-22 17:23:59 -0800'
slug: how-to-route-emails-with-action-mailbox
description: Action Mailbox is a feature released in Rails 6 that allows you to receive
  emails in your application, using SendGrid's Inbound Parse...
original_id: 46
image: "/assets/images/posts/how-to-route-emails-with-action-mailbox/action-mailbox-dumpster-fire-2020.jpg"
cover: "/assets/images/posts/how-to-route-emails-with-action-mailbox/action-mailbox-dumpster-fire-2020.jpg"
---

[Action Mailbox](https://guides.rubyonrails.org/action_mailbox_basics.html) is a feature introduced in Rails 6 that enables you to route incoming emails to controller-like mailboxes. It opens up interesting use cases for how you can deal with inbound email in your own application. There is perhaps no better showcase of more creative use than the super necessary Dumpster Fire by Basecamp—a clever, and cathartic display (with top-notch tunes) that invites you to encapsulate your opinion of 2020 in email form, so that it may be incinerated via dumpster fire. We'll do a rundown of how to integrate with [SendGrid](https://sendgrid.com/)'s Parse service, and relay emails to ingress in a Rails application in production.

> **The More You Know**: Your custom domain must have a _Secure Socket Layer (SSL)_ certificate for emails to be routed. https:// encrypts the transmission of email messages which might contain sensitive data. Gmail uses the Transport Layer Security (TLS) protocol by default—the successor to SSL.

Action Mailbox comes with a built-in incineration background job, as a safety measure to prevent storing of sensitive emails. If you are on Heroku, you can simply point to the app URL instead of your custom domain: your-app.herokuapp.com, which has Automated Certificate Management (ACM) available for applications running on paid dynos.

**Configure SendGrid**

In SendGrid's [parse settings](https://app.sendgrid.com/settings/parse), click on Add Host & URL. Make sure you select **POST the raw, full MIME message**, as required by Rails, and a subdomain that is unique. The URL has to be in the specified format:

```
https://actionmailbox:<password>@<domain>/rails/action_mailbox/sendgrid/inbound_emails
```

In your domain host's control panel, add an MX record _without_ subdomain: **mx.sendgrid.net**, and **@** as the host, as they typically don't allow null values.

I use [DigitalOcean](https://www.digitalocean.com/) to manage all of my domains, as their Networking DNS management is much more user-friendly than traditional hosting platforms, and integrates with their Load Balancers and Spaces to streamline automatic SSL management.

**Install Gems**

Action Mailbox comes with an IncinerationJob that "incinerates" the inbound email after a default of 30 days, to ensure you're not holding on to sensitive data. My preference for background processing is [Sidekiq](https://adamnaamani.com/background-processing-with-rets-and-sidekiq/).

```ruby
gem 'sendgrid-ruby'
gem 'sidekiq'
gem 'redis'
```

**Sending Email with Action Mailer**

To send emails _from_ your application, configure the Action Mailer smtp\_settings with the username of apikey and its associated value in the password field, which can be created in SendGrid's dashboard and stored in your credentials.

```ruby
# config/environment.rb
ActionMailer::Base.smtp_settings = {
  user_name: 'apikey',
  password: Rails.application.credentials.dig(:sendgrid, :api_key),
  domain: <domain>,
  address: 'smtp.sendgrid.net',
  port: 587,
  authentication: :plain,
  enable_starttls_auto: true
}
```

**Set Credentials**

Rails credentials are the only form of storing passwords and environment variables that I like to use, as it's incredibly easy to encrypt, access, and transfer in git.

```bash
> EDITOR="code --wait" rails credentials:edit

action_mailbox:
ingress_password: ...
```

**Set Variables on Heroku**

Environment variables can be set using [Heroku's CLI](https://devcenter.heroku.com/articles/heroku-cli), or in your app's settings.

```bash
heroku config:set RAILS_INBOUND_EMAIL_PASSWORD=...
heroku config:set RAILS_MASTER_KEY=...
heroku config:set SECRET_KEY_BASE=...
heroku config:set SENDGRID_API_KEY=...
```

**Route Emails in Rails**

You can write any regular expression to route emails to different mailboxes, however for my purposes, I just used routing all:. You can generate mailboxes using a Rails command:

```ruby
bin/rails action_mailbox:install
bin/rails db:migrate
bin/rails generate mailbox supportclass ApplicationMailbox < ActionMailbox::Base
routing all: :support
end

class SupportMailbox < ApplicationMailbox
  def process
    # ...
  end
end
```

**Test with RSpec**

Require ActionMailbox test helpers to expose methods, then run RSpec to test the mail status is delivered:

```ruby
# spec/rails_helper.rb
require 'action_mailbox/test_helper'

RSpec.configure do |config|
  config.include ActionMailbox::TestHelper, type: :mailbox
end

# spec/mailboxes/support_mailbox_spec.rb
require 'rails_helper'

RSpec.describe SupportMailbox, type: :mailbox do
  subject do
    receive_inbound_email_from_mail(
      from: 'anyone@gmail.com',
      to: 'me@email.com',
      subject: 'Sample subject',
      body: "Sample body"
    )
  end

  it 'should have status delivered' do
    expect(subject.status).to eq('delivered')
  end
end

> rspec
```

Now send an email to your custom domain: your@email.com, and depending on how you set up your active storage (my preference is Amazon S3), you should see the inbound email.
