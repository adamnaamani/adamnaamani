---
layout: post
title: Managing Subscriptions with Stripe Checkout
date: '2020-11-26 18:45:27 -0800'
slug: managing-subscriptions-with-stripe-checkout
description: Founded in 2010 by Patrick and John Collison, Stripe has democratized
  online payment processing for internet businesses around the world.
image: "/assets/images/posts/managing-subscriptions-with-stripe-checkout/stripe-checkout-social.png"
cover: "/assets/images/posts/managing-subscriptions-with-stripe-checkout/stripe-checkout-social.png"
---

Software as a service ([SaaS](https://adamnaamani.com/saas-fintech/)) nowadays makes it easy to integrate e-commerce solutions into your application, and nothing comes close to the capabilities of [Stripe](https://stripe.com). Founded in 2010 by Patrick and John Collison, Stripe has democratized online payment processing for internet businesses around the world—handling financial infrastructure for some of the largest companies like Amazon, Lyft, DoorDash, and Shopify.

The private company's latest funding round could potentially value them at [$70+ billion](https://www.bloomberg.com/news/articles/2020-11-24/payments-startup-stripe-is-said-in-talks-to-raise-new-funding), making it the most valuable venture-backed startup in the U.S. Having learned to code at an early age, the two founding brothers became teenage millionaires when they sold their first company, [Auctomatic](https://www.cnet.com/news/canadian-media-company-buys-auctomatic-for-5-million/) in 2008.

> "_What we did discover pretty quickly was that the hardest part of starting an internet business isn’t coming up with the idea, turning the idea into code or getting people to hear about it and pay for it. The hardest part was finding a way to accept customers’ money._" – _John Collison_

Stripe processes payments through their own servers, so that payers and vendors can connect with minimal friction. Particularly for startups, it could save months of development time, and effectively offload security concerns to Stripe. They act as a white-label merchant account with advanced fraud detection, at a 2.9% + $0.30 [fee](https://stripe.com/en-ca/pricing) per successful card charge.

Their ambition (or north star) is to "increase the GDP of the internet", with a focus on targeting entrepreneurs in underserved markets. They process hundreds of billions of dollars each year, 250+ million API requests per day, with 90% of U.S. adults having bought from businesses using Stripe, many likely unknowingly.

The focus here will be on the vast array of tools that developers can use to integrate with the battle-tested Stripe Payments platform. Stripe provides services via their API, or a pre-built Checkout page, along with a [Ruby client](https://github.com/stripe/stripe-ruby) that works seamlessly with Rails.

```ruby
gem 'stripe'
```

Interacting with their API can be done through [Stripe Elements](https://stripe.com/en-ca/payments/elements), which may require building additional UI components, but the quicker and more secure option for managing sensitive user credentials is through a conversion-optimized [Stripe Checkout](https://stripe.com/docs/payments/checkout) form. Checkout offers a payment gateway to delegate the responsibility of securely handling the transmission of customer credit card information.

Validation, error handling, and protecting sensitive user data can take up many engineering hours that could be better allocated towards building a great product. Checkout makes it easy to accept different forms of payment, including Apple Pay, that uses native functionality on mobile devices like fingerprint or facial recognition for an additional layer of security.

Considering changing browser standards, device responsiveness, language translation, cost, and compliance for one of the most important aspects of your business, I would much rather not reinvent the wheel, and let Stripe sweat the details when it comes to collecting payments.

Bundled with the official Stripe gem is a Session service used to make the API calls. There are a variety of libraries in different languages you can use to interact with Stripe's platform, but in this example we'll create a request in Rails to initialize a new session and return the response that will allow us to redirect to the checkout page.

```ruby
module Checkout
  class Session
    include Service

    def initialize(params:)
      @params = params
    end

    def call
      new_session
    rescue Stripe::StripeError => e
      Rails.logger.error(e)
    end

    private

    def new_session
      session = Stripe::Checkout::Session.create(session_params)

      { id: session.id }.to_json
    end

    def session_params
      {
        mode: 'subscription',
        success_url: "/success?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: "/pricing",
        payment_method_types: ['card'],
        customer: @params[:stripe_customer_id],
        line_items: [{
            quantity: 1,
            price: @params[:price_id]
          }]
      }
    end
  end
end
```

Two things to note in the session request object are :price\_id and :stripe\_customer\_id. The :price\_id represents the subscription tier which can either be created in the dashboard, or programatically through the API, and is represented by a hash: price\_1HcQkJKB14RpauEDKfzS8dal.

The :stripe\_customer\_id follows a similar string representation: cus\_HRMRd2bzzW06AI. It can be stored in your database, and is all that's really required to link your user with Stripe's customer profile. We can then create the checkout session from the front-end, in this case React, with an HTTP client like [axios](https://www.npmjs.com/package/axios), and Stripe's npm package [stripe-js](https://github.com/stripe/stripe-js). You just need your [publishable api key](https://stripe.com/docs/keys) to load the client, and redirect to the checkout page upon successful response.

```js
import React from 'react'
import axios from 'axios'
import { loadStripe } from '@stripe/stripe-js'

const Checkout = () => {
  const stripe = loadStripe('<publishable-api-key>')

  const handleSelect = () => {
    axios.post('/checkout', { customerId, priceId })
    .then(({ data }) => {
        stripe.redirectToCheckout({
            sessionId: data.id,
        })
    })
  }
}
```

The success url defined in the session object will contain the CHECKOUT\_SESSION\_ID parameter, which can then be used to retrieve information about the payment status—although [webhook](https://stripe.com/docs/webhooks) events are preferred over url params for automatically triggered reactions.

Even more impressive than the vast array of developer tools, is the diversity of Stripe as a company. They provide services beyond payment processing, in corporate finance, credit cards, investments, and loans—which are now automatically analyzed and approved using a customer's historical performance and machine learning models, all without human intervention.

> "_A big part of what we’re trying to do with Stripe is continually make it easy for new business to start, and for new businesses to succeed. Having commerce and direct payment succeed on the internet is a very important component of that. It’s the final piece in the Dream Machine._” _– John Collison_
