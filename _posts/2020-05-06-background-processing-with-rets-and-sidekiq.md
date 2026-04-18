---
layout: post
title: Background Processing with RETS and Sidekiq
date: '2020-05-06 01:01:18 -0700'
slug: background-processing-with-rets-and-sidekiq
description: I've been predominantly working with two libraries that tie perfectly
  into Rails' ActiveJob — Resque and Sidekiq. My preference leans towards Sidekiq
original_id: 29
image: "/assets/images/posts/background-processing-with-rets-and-sidekiq/sidekiq-rets.png"
cover: "/assets/images/posts/background-processing-with-rets-and-sidekiq/sidekiq-rets.png"
---

Managing large quantities of real estate data is computationally intensive, and well-suited for background processing. The task involves importing thousands of MLS® listings into a [Redis](https://redis.io) in-memory data structure store, using an open government API for geocoding, and association with other models, therefore a lot can go wrong, and it's important to isolate these functions according to the [single responsibility principle](https://en.wikipedia.org/wiki/Single-responsibility_principle) and [separation of concerns](https://en.wikipedia.org/wiki/Separation_of_concerns).

This is an attempt to find the optimal setup using [Heroku Redis](https://elements.heroku.com/addons/heroku-redis) in regards to concurrency and pool size, while gracefully dealing with Timeout, 429 Too Many Requests, and ERR max number of clients reached errors. I've predominantly worked with two libraries that tie perfectly into Rails' [ActiveJob](https://edgeguides.rubyonrails.org/active_job_basics.html) — [Resque](https://github.com/resque/resque) and [Sidekiq](https://github.com/mperham/sidekiq). My preference leans toward Sidekiq, not only for their sweet karate logo but the creator, who open-sourced the software and charged money for Pro features that allowed him to [quit his job](https://www.indiehackers.com/interview/how-charging-money-for-pro-features-allowed-me-quit-my-job-6e71309457):

> "_I've been working daily for the last 5 years as a solo entrepreneur, building as much value into my commercial products and automating my business as much as possible. It's time to take a vacation and enjoy my success for a few months — relax and enjoy life while the products sell themselves._" _– Mike Perham_

Suffice it to say, that enthusiasm for software engineering and independence is reflected in the product, and it helps that he frequently answers questions on [StackOverflow](https://stackoverflow.com) for when you run into issues (also a [happy hour](https://sidekiq.org/support.html) for support). Sidekiq has tight integration with ActiveJob, which has worked great so far, to varying degrees.

**Jobs within a Job**

This one took me a while to figure out. It doesn't make much sense to perform a request to a third-party API outside of the job only to pass it _to_ a job. That request could Timeout, or respond with a 400, and is not the most effective way to use background processing as it was intended. I ended up creating one job that connects to the RETS client using [Estately's RETS library](https://github.com/estately/rets), which loops over all the records and queues a new job for every row.

**Connect to RETS client:**

```
module Rets
extend ActiveSupport::Concern

def connect
retries = 5

@client = Rets::Client.new(
login_url: :endpoint,
username: :user,
password: :password,
version: 'RETS/1.5',
max_retries: retries
)
@client.login
rescue Timeout::Error => e
Rails.logger.error(e)
retry if retries.positive?
retries -= 1
end

def disconnect
@client.logout
end
end
```

**Import records:**

```
module Import
class ListingJob < ApplicationJob
queue_as :priority

before_perform :connect
after_perform :disconnect

sidekiq_options retry: 5

def perform(**args)
records = @client.find(
:all,
search_type: args[:search_type],
class: args[:property_class],
resolve: true
)

return if records.blank?

records.each do |record|
Insert::ListingJob.perform_later(record)
end
rescue StandardError => e
Rails.logger.error(e)
Raven.capture_exception(e)
end
end
end
```

**Insert record:**

```
module Insert
class ListingJob < ApplicationJob
queue_as :priority

def perform(record)
Listings::Create.call(record) if record.present?
end
end
end
```

Sidekiq then calls a Plain Old Ruby Object (PORO) service to handle the interaction with the database. The operation can be seen through Sidekiq's sleek dashboard:

```
Rails.application.routes.draw do
require 'sidekiq/web'
require 'sidekiq-scheduler/web'
mount Sidekiq::Web => '/sidekiq'
end
```

The jobs can be controlled through the UI, or programmatically through the Rails console, which makes it super easy to manage:

```
2.7.1 > queue = Sidekiq::Queue.new('priority')
2.7.1 > queue.each do |job|
2.7.1 > job.delete
2.7.1 > end
```
