---
layout: post
title: Streaming Real Estate Data
date: '2020-06-14 20:18:35 -0700'
slug: streaming-real-estate-data
description: Big data in real estate is a prime use case for real-time stream processing–a
  programming paradigm that allows us to instantaneously...
original_id: 34
image: "/assets/images/posts/streaming-real-estate-data/streaming-real-estate-data-lake-aws.png"
cover: "/assets/images/posts/streaming-real-estate-data/streaming-real-estate-data-lake-aws.png"
---

Big data in real estate is a prime use case for real-time stream processing—a programming paradigm that allows us to instantaneously respond to data as it arrives. It is the antithesis to batch processing, whereby all data is loaded into memory before it is delivered and processed. The real estate profession is truly a matter of time is money—if an appraisal is a day late, or there is a lack of efficiency in the transaction process, it could lead to a deal collapsing, putting the livelihood of all parties involved at stake.

The time sensitive nature of real estate demands a level of immediacy—from responding to client enquiries (now typically automated by chat bots), validating big data as it is imported into a [data lake](https://aws.amazon.com/big-data/datalakes-and-analytics/what-is-a-data-lake/), or generating an estimate of property value upon offer request (in the iBuyer space). Real-time streaming and data processing provide the mechanisms for organizations to generate business value from their data and outperform the competition.

To this day, the real estate industry is mired in complex layers of policies, compliance requirements, and varying degrees of data access. There still exists a lack of consistent, cost effective, consolidated options for real estate professionals to gain control over Multiple Listing Service (MLS) data. Additionally, it is prohibitively difficult to standardize and assimilate property information, make it user-friendly, and useful. Real estate in the modern era poses a significant engineering challenge—particularly with the shift to unbundling and digitizing of nearly every stage of the transaction. The technical burden should not be of concern to real estate firms that ought to focus on the business of selling rather than building software.

This post will continue an exploration into methods of [importing MLS data](https://adamnaamani.com/background-processing-with-rets-and-sidekiq/) through the Real Estate Transaction Standard (RETS) protocol. Granted, while this is a deprecated, older standard of transferring data within the real estate industry, we can still build a facade so that the underlying functionality can be implemented through a consistent interface, much like how Rails promotes convention over configuration. The more modern [RESO Web API](https://www.reso.org/reso-web-api/) uses open standards that are more familiar in today's technical environment, such as OAuth and RESTful design (to a sigh of relief). Brokers and technology companies, however, are still required to request data through the MLSs, which is a whole other matter in itself.

To access listings from the real estate boards, we'll use a Node.js RETS client, aptly named, [rets-client](https://github.com/sbruno81/rets-client), as well as [ActionCable](https://guides.rubyonrails.org/action_cable_overview.html) in Rails 6 to broadcast the streamed listings to a subscriber for consumption in a React front-end. ActionCable seamlessly integrates the WebSocket API—an advanced technology that opens up a two-way communication session between the server and client—much like how Twitter displays new tweets in its timeline. In the Node script, [through2](https://github.com/rvagg/through2) will be used as a tiny wrapper around built-in Node.js streams. Each listing will be processed asynchronously in a transformFunction, with a callback to indicate that the transformation is done.

> _Process data in motion. Read/write input into output sequentially. Instead of reading a file into memory all at once, read in chunks. Handle volumes much larger, in significantly less time._

I've had success integrating [other technologies](https://adamnaamani.com/aws-lambda-functions-for-python-and-ruby/) into a Ruby on Rails application, but Node.js takes the cake. After installing Node with Brew, a simple .js file in the root of the application is enough to get the ball rolling:

```
brew install node
node rets.js
```

This opens up the wonderful world of Node.js, and extends the capabilities of a Rails and React application. Node is simple to adopt, as it is basically a JavaScript runtime environment that executes JavaScript code (outside a web browser). We'll use [axios](https://github.com/axios/axios) as our http client (as I have mentioned before in a previous [post on authentication](https://adamnaamani.com/jwt-authentication-with-warden-and-devise/)) that will log into the Rails API and include the generated Authorization token in the header with every request. I've set up a [Thor](http://whatisthor.com/) task to trigger the .js script and start the import, which will be automated to run on a daily schedule. The task uses Ruby's system method to execute commands in a subshell, and pass environment variables as our parameters:

```
class Rets < Thor
desc 'node [resource] [table]', 'stream mls listings'
def node(resource, table)
# ...
system(%(#{env_vars} node ./rets.js))
end
end
```

Before connecting to the RETS client, there are a few fundamental concepts to grasp in Node.js that will give us a better understanding of how to work with streams:

**Types of Streams**

- **Writeable**: Streams to which data can be written.
- **Readable**: Streams from which data can be read.
- **Duplex**: Streams that are both Readable and Writable.
- **Transform**: Duplex streams that can modify or transform the data as it is written and read.

**Pipelining**

The pipe() function is the primary composition operator in Node.js's built-in stream module, which pipes content from any _readable_ source to any _writeable_ destination. Working with a duplex stream, you can also chain pipe calls to run in sequence and transform the data as it is written and read:

```
stream
.pipe(mapKeys())
.pipe(standardizeData())
.pipe(geocodeAddress())
.pipe(toJSON())
.pipe(process.stdout)
```

**Async Iterator**

In order to transform the input from a readable stream, it is recommended to set up an asynchronous iteration function. This function will post the streamed listing to the Rails application through axios, and run the callback upon successful response to signal the next iteration:

```
const doAsyncProcessing = (row, index, callback) => {
axios.post(Routes.api_v1_listings(), {
listing: row,
}).then(({ data }) => {
console.log(`----Streamed: ${index}----`)
callback()
}).catch((error) => {
console.log(error)
})
}
```

**Reading Modes**

Readable streams have two modes that control how they are consumed, also referred to as _push_ and _pull_:

1. **Flowing**: Data is read and provided quickly using the EventEmitter interface. The stream is switched to flowing mode by a data event handler, calling stream.resume() or stream.pipe().
2. **Paused**: State in which all Readable streams begin. In order to read chunks of data, the stream.read() method must be called.

Now for the fun part...logging in to the RETS server and fetching the listings. I find simple joy in working with something as complex as MLS data. Perhaps because there is so much meaning behind the words, numbers, and images—representative of the emotional nature tied to the purchase of property.

There are an incredible number of data points to consider during the entire sales process. An MLS listing alone has around **~350** attributes that need validation, normalization, and standardization. While we won't get into the specifics (more on that in a subsequent article), we will analyze the metadata for the resources we will be able to access. This can be done in a number of ways, but rets-client does a great job of making it as simple as possible:

```
rets.getAutoLogoutClient({
loginUrl: LOGIN_URL,
username: USERNAME,
password: PASSWORD,
}, async (client) => {
await client.metadata.getResources()
})
```

Metadata can show us a variety of different formats in which data is structured. Most often there will be standard resources such as:

- Property
- Deleted
- OpenHouse
- Media

The Property resource will have class names such as:

- RD\_1: Residential Detached
- RA\_2: Residential Attached
- MF\_3: Multifamily
- LD\_4: Lots and Land

A quicker method to query RETS servers would involve using a CLI, and I haven't found one better than [retscli](https://github.com/summera/retscli)—a gem built on top of Estately's [rets](https://github.com/estately/rets), which I [wrote about before](https://adamnaamani.com/background-processing-with-rets-and-sidekiq/). Here is the function that will do the heavy lifting, which I've adopted from the rets-client example usage:

```
rets.getAutoLogoutClient(clientSettings, async (client) => {
authenticate()
getResources(client)

await new Promise((resolve, reject) => {
let count = 0
const streamResult = client.search.stream.query(
RESOURCE,
TABLE,
COUNT,
LIMIT_OBJ
)

const processor = through2.obj((event, _encoding, callback) => {
switch (event.type) {
case 'headerInfo':
console.log(event.payload)
callback()
break
case 'data':
count += 1
doAsyncProcessing(event.payload, count, callback)
break
case 'done':
resolve(event.payload.rowsReceived)
break
case 'error':
console.log(`Error: ${event.payload}`)
streamResult.retsStream.unpipe(processor)
processor.end()
reject(event.payload)
callback()
break
default:
callback()
}
})

streamResult.retsStream.pipe(processor)
}).catch((error) => {
console.log(error)
})
})
```

I was pleasantly surprised to see how much more of an efficient tool this was to import MLS listings than any others I've tried. Sure, there are more capable solutions that exist, but this does what I needed it to do. I would argue the possibilities expand in proportion to the amount of capital invested in solving these challenges, however, thinking in bootstrapping terms, it still amazes me how much we can accomplish with a text editor, open-source software, some ambition to solve problems, and a lot of patience.

As the cherry on top, I set up ActionCable to broadcast the creation of a new listing that will automatically stream the object to a variety of different layers for instant notifications, analytics, monitoring, and machine learning.

```
def create
authorize new_listing

return head :unprocessable_entity unless new_listing.valid?

broadcast

render json: ListingSerializer.new(new_listing).serialized_json
end

private

def broadcast
ListingChannel.broadcast_to(current_user, new_listing.to_json)
endListingChannel.subscribe({
received: handleReceived,
})
```
