---
layout: post
title: ChatGPT for Real Estate
date: '2023-03-09 13:30:00 -0800'
slug: chatgpt-for-real-estate
description: The new ChatGPT API calls gpt-3.5-turbo, the same model used in their
  ChatGPT product. It’s their best model for many non-chat use cases.
original_id: 95
---

The long-anticipated ChatGPT and Whisper APIs were released on March 1, 2023, giving developers access to cutting-edge language and speech-to-text capabilities:

> "_Through a series of system-wide optimizations, we’ve achieved 90% cost reduction for ChatGPT since December; we’re now passing through those savings to API users. Developers can now use our open-source Whisper large-v2 model in the API with much faster and cost-effective results. ChatGPT API users can expect continuous model improvements and the option to choose dedicated capacity for deeper control over the models. We’ve also listened closely to feedback from our developers and refined our API terms of service to better meet their needs._" _– OpenAI_

The new ChatGPT API calls gpt-3.5-turbo, the same model used in their [ChatGPT](https://chat.openai.com) product. It’s their best model for many non-chat use cases. AI is the most significant platform shift that will bring a new wave of innovation and disruption to every industry far and wide. I've been experimenting with how this technology could be applied to real estate, beyond the already ubiquitous automated listing descriptions.

One useful outcome I discovered with ChatGPT was learning how to query a RETS server for a listing photo's object attributes, considering RETS is an archaic technology. Storing thousands of photos on a service like Amazon S3 can become costly, and is a strain on an application's resources. I entered a prompt in ChatGPT: "_How do I request the photo URL from the RETS API in Ruby_", and it brilliantly suggested one line of code that I could implement to access photos directly from the original storage location.

```
Rets::Client.new.objects(
'*',
resource: 'Property',
object_type: 'Photo',
resource_id: sysid,
location: 1
)
```

The new Chat API is priced at $0.002 per 1K tokens, which is 10x cheaper than the existing GPT-3.5 models. Data submitted to OpenAPI is not used for training, and they have a 30-day retention policy. Code completions are one of the many incredible responses from the API, but adjusting the inputs enables you to realize the true potential this tool has to offer.

The main input is the messages parameter, which takes an array of objects with role and content key/value pairs. There are 3 roles you can program for a more accurate response: system, assistant, and user. Conversations can be as short as 1 message or fill many pages. Typically, a conversation is formatted with a system message first, followed by alternating user and assistant roles.

```
[
{
role: "system",
content: 'You are a helpful real estate agent.'
},
{
role: "system",
content: @listing.as_json.compact_blank.to_json
},
{
role: "assistant",
content: @assistant.to_json
},
{
role: "user",
content: @prompt.to_s
}
]
```

For the chat to have a real estate context, I added a system message to set the behaviour of the agent. gpt-3.5-turbo currently doesn't always pay strong attention to system messages, but future models will be trained to do so. The next system message is where it gets really interesting. A typical MLS® real estate listing has about ~250 attributes—many of them blank, and if you include them in the API call it will count as a token (pieces of words used for natural language processing) and run up your model usage fairly quickly.

It's important to first omit any empty fields and only supply those that are relevant to the request. With a more specific set of input data, the user can enter a prompt about a particular listing and get a response that analyzes and incorporates all the listing fields. You can ask ChatGPT a variety of real estate related questions such as:

- What are the demographics in the area?
- What are the lot dimensions?
- How close is this area to Downtown?
- What is leasehold pre-paid strata?
- What is the monthly payment including property taxes and strata fees?
