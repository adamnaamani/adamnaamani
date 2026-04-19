---
layout: post
title: Transferring Data in Postgres
date: '2020-08-22 14:09:16 -0700'
slug: transferring-data-in-postgres
description: Postgres has two commands that make it simple to extract a database and
  restore it to another destination, with flexible options...
original_id: 37
image: "/assets/images/posts/transferring-data-in-postgres/heroku-postgres-datastore.png"
cover: "/assets/images/posts/transferring-data-in-postgres/heroku-postgres-datastore.png"
---

> "_We believe that databases need to excel at more than simple selects to be useful for complex tasks, and our positive experiences with PostgreSQL has done nothing but reinforce that philosophy._" _– David McNett_

Migrating data hardly ever comes without headaches and the odd "oh shit" moment, but after getting the hang of it, you realize a great level of control.

Postgres comes with two utilities that make it simple to extract a database and restore it to another destination, with flexible options to select which parts of the data you want restored:

- [pg\_dump](https://www.postgresql.org/docs/11/app-pgdump.html) is a utility for consistent back-ups of a PostgreSQL database, even if the database is being used concurrently.
- [pg\_restore](https://www.postgresql.org/docs/9.2/app-pgrestore.html) is a utility for restoring a PostgreSQL database from an archive created by pg\_dump in one of the non-plain-text formats.

If your database is set up through [Heroku](https://www.heroku.com/) (which is based on AWS) you can run the same commands, omitting heroku run, as there is no built-in function. All that's required is the Heroku database URL, which can be found through the data store settings.

Heroku has some of the best support of any PaaS, and they have often provided quicker, more thorough responses than you would find on StackOverflow. Their team suggested two commands to transfer individual tables using the -t flag, establishing a connection from your local machine to the Heroku Postgres instance.

**Step 1: Dump**

```bash
pg_dump -Fc -t <table> <database> > latest.dump
```

**Step 2: Restore**

```bash
pg_restore -d <database> -t <table> -a latest.dump
```

- -Fc: Output a custom-format archive.
- -t: Dump only matching tables.
- -a: Dump only the data, not the schema.

The process would be similar if you were using a database that isn't managed by Heroku (such as [RDS](https://adamnaamani.com/multiple-databases-with-rails-6-and-amazon-rds/)), in that the URI is typically formed as follows:

```
postgres://<user>:<password>@<host>:<port>/<database>
```

Postgres utilities are only some of the reasons I enjoy working with the world's most advanced open source relational database–as it excels in many other areas such as data types, data integrity, performance, and reliability.
