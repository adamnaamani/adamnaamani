---
layout: post
title: Multiple Databases with Rails 6 and RDS
date: '2020-05-17 19:26:28 -0700'
slug: multiple-databases-with-rails-6-and-amazon-rds
description: Rails 6 shipped with the ability to use multiple RDS databases in one
  application, making automatic connection switching as simple as...
image: "/assets/images/posts/multiple-databases-with-rails-6-and-amazon-rds/rails-6-amazon-rds.png"
cover: "/assets/images/posts/multiple-databases-with-rails-6-and-amazon-rds/rails-6-amazon-rds.png"
---

Rails 6 shipped with the ability to use [multiple databases](https://guides.rubyonrails.org/active_record_multiple_databases.html) in one application, making automatic connection switching as simple as adding a connects\_to method in the respective class. To go a step further, we'll set up an [Amazon RDS](https://aws.amazon.com/rds/) instance, which benefits team members by providing consistent access to the same database—which could contain a copy of production data that will be useful to test against—avoiding development environment configuration, and improving horizontal scaling.

AWS offers a free tier for RDS, with 750 hours of db.t2.micro instance usage, 20 GB of General Purpose (SSD) DB Storage, and 20 GB of backup storage for automated database backups. The free tier is available for 12 months from the account creation date.

> "_The service handles time-consuming database management tasks so you can pursue higher value application development._" _– AWS_

We'll first want to create a database in the [Amazon RDS console](https://aws.amazon.com/rds/) using the Standard Create method with PostgreSQL. You should set Publicly Accessible to Yes in order to connect from the Rails application.

Once the instance is ready, it will provide an endpoint:

```
<app>.ca-central-1.rds.amazonaws.com
```

If you're using [PostGIS](https://postgis.net/install/), you'll want to create the extension, and prefix the url with postgis:

```sql
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
CREATE EXTENSION address_standardizer;
CREATE EXTENSION postgis_tiger_geocoder;postgis://<user>:<pass>@<app>.ca-central-1.rds.amazonaws.com:<port>/<database>
```

Now in the Rails application's database.yml file, we have to specify the url, database, and migrations\_path. To add replica databases, include replica: true, and ensure it has the same database name:

```yaml
default: &default
adapter: postgis
encoding: unicode
postgis_extension: true
schema_search_path: 'public,postgis'
host: localhost
pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
timeout: 5000
port: 5432

development:
primary:
<<: *default
database: development
primary_replica:
<<: *default
database: development
replica: true
rds:
<<: *default
url: endpoint
database: development_rds
migrations_path: db/migrate_rds
rds_replica:
<<: *default
url: endpoint
database: development_rds
replica: true
```

Rails middleware adds basic automatic switching from primary to replica based on the HTTP verb:

```ruby
module App
  class Application < Rails::Application
    config.active_record.database_selector = {
      delay: 2.seconds
    }
  end
end
```

Now all that's needed is to set up the models by connecting to the new database:

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: {
    writing: :primary,
    reading: :primary_replica
  }
  endclass Geojson < ApplicationRecord
  connects_to database: {
    writing: :rds,
    reading: :rds_replica
  }
end
```
