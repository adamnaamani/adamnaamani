---
layout: post
title: AWS Lambda Functions for Python and Ruby
date: '2020-05-08 19:09:14 -0700'
slug: aws-lambda-functions-for-python-and-ruby
description: The aws-sdk-lambda library makes serverless computing dead simple, by
  providing a gateway that connects to a Lambda function.
image: "/assets/images/posts/aws-lambda-functions-for-python-and-ruby/aws-lambda-ruby-python.png"
cover: "/assets/images/posts/aws-lambda-functions-for-python-and-ruby/aws-lambda-ruby-python.png"
---

I love to program in [Ruby](https://adamnaamani.com/background-processing-with-rets-and-sidekiq/) as well as [Python](https://adamnaamani.com/python-for-real-estate/), and [AWS Lambda](https://aws.amazon.com/lambda/) functions provide the perfect solution to combine both languages' capabilities without additional server configuration. The [aws-sdk-lambda](https://rubygems.org/gems/aws-sdk-lambda/versions/1.0.0.rc8) library makes [serverless computing](https://en.wikipedia.org/wiki/Serverless_computing) workflow dead simple, by providing a gateway that connects to a Lambda function that will run Python code and return the results to a Rails application.

> "_Run code without thinking about servers. Pay only for the compute time you consume_." _– AWS_

The primary motive for integrating Python is that it provides a rich set of [Machine Learning tools](https://github.com/adamnaamani/handbook/blob/master/pages/machine-learning.md) to analyze Real Estate data. Much of what I wanted to accomplish, I could have with one script in a [Jupyter Notebook](https://jupyter.org/), but integrating that functionality at scale would require a lot of overhead and building another API.

AWS does much of the heavy-lifting tasks like server provisioning and management, which can be monitored through their web interface.

Lambda passes an event parameter (usually of the Python dict type) as well as a context object to the handler—providing methods and properties with information about the invocation, function, and execution environment.

```python
import json
import scipy

def lambda_handler(event, context):
  return {
    'statusCode': 200,
    'body': {}
  }
```

Here are the simple steps to get up and running with AWS:

**1. Install the** [**aws-cli**](https://github.com/aws/aws-cli)

```bash
$ brew install aws-cli
$ aws configure
AWS Access Key ID: <access_key_id>
AWS Secret Access Key: <secret_access_key>
Default region name [us-west-2]: <default_region>
Default output format [None]: json
$ aws lambda list-functions
```

**2. Add aws-sdk-lambda to Gemfile**

```ruby
gem 'aws-sdk-lambda', '~> 1.4', require: false
```

**3. Connect to Aws::Lambda::Client**

```ruby
module Lambda
  class Python
    require 'aws-sdk-lambda'
    include Service

    REGION = 'us-east-1'.freeze

    def initialize(**params)
      @params = params
    end

    def call
      response = client.invoke(options)
      response_payload = JSON.parse(
        response.payload.string,
        symbolize_names: true
      )
      JSON.parse(response_payload[:body])
    end

    private

    def request_object
      @request_object ||= Listing.lambda_object.to_json
    end

    def permitted_params
      {
        SortBy: 'time',
        SortOrder: 'descending',
        NumberToGet: 10,
        CustomObject: request_object
      }
    end

    def payload
      @payload ||= JSON.generate(permitted_params)
    end

    def options
      {
        function_name: 'PythonClient',
        invocation_type: 'RequestResponse',
        log_type: 'None',
        payload: payload
      }
    end

    def client
      @client ||= Aws::Lambda::Client.new(
        region: REGION,
        access_key_id: :access_key_id,
        secret_access_key: :secret_access_key
      )
    end
  end
end
```

This configuration opens up many doors to fully leverage what Ruby and Python have to offer. As an added benefit, you are only charged for every **100ms** that your code executes, saving you unnecessary compute time costs. Provisioned Concurrency keeps your functions initialized and responsive within double-digit milliseconds.

AWS Lambda enables the use of Python's powerful libraries to validate, normalize, and analyze property data before it is moved to a data store, all while maintaining [programmer happiness](https://rubyonrails.org/doctrine/#optimize-for-programmer-happiness) with Ruby on Rails.
