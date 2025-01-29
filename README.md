# never-miss-pilates

## What's this

A homemade quick app (1 weekend POC) to self-book me into my two gym's (CLT & CRC) pilates and Group Cycle classes respectively (because they always get full). 
Multi-tenant so my friends can use it as well. 


[Loom demo](https://www.loom.com/share/965331d616b84c528db8f94e150ed587?sid=3a1ca853-7045-43b2-b97c-9f7990b226b6)



<img width="1352" alt="Screenshot 2025-01-29 at 8 39 55 PM" src="https://github.com/user-attachments/assets/51fe4e90-c0bf-4bad-87c8-c1d5b09bbd2e" />


### Running the tasks

The scraping tasks run every 5 minutes. You can also trigger them manually from the admin's "Desired Bookings" tab. 

---

## Dev setup

### How it works 

### CRC:

The CRC gym provides a mobile application so there is a RESTful API we can leverage (as opposed to the web-scraping for CLT). 
The admin user must first configure their `crc_email` and `crc_password` from the dashboard.
Every five minutes, a job is triggered for each enabled booking that performs the following steps:

1. Calculates the next date and time for the booking based on the desired day of the week and time.
2. If this datetime is more than 24 hours in the future, it simply skips since CRC does not permit bookings made too far in advance.
3. Checks if a booking for the same datetime already exists in our database. If it does, it skips.
4. If the `admin_user` row lacks a `crc_user_id` or `crc_token`, we will first initiate an HTTP POST request to log in and retrieve these credentials, storing them for future use (until they expire).
5. Performs an HTTP GET request to locate the class ID that matches the user’s desired booking settings.
6. After identifying the class id, the job proceeds with an HTTP POST request to book the class. Depending on the response result, it re-authenticates and retries, or attempts the next preferred station (aka bike).
7. Once the booking succeeds, it creates a `booking` record, to prevent redundant booking attempts. This is crucial especially if a booking was intentionally cancelled via the CRC app to prevent unintentional re-booking.

### Pre requisites

- Postgres
- Redis
- liv (`brew install vips`)
- Ruby (Recommendations: install with `rbenv`)

### Installation

Clone this repository on your local machine.

Install the correct version of ruby that you can find in `.ruby-version` file.
Example with `rbenv` (double-check project ruby version in Gemfile in case it got updated):

```console
rbenv install 3.2.2; rbenv local 3.2.2;
```

### Setup gems:

```console
gem install bundler
bundle install
gem install foreman
```

### Initialize the databases:

Make sure you have `postgres` running.

Copy the file `.env.example` as `.env` and adjust if needed. The keys are just sample keys, so if you need them, ask a fellow developer.

```console
rake db:create; rake db:schema:load
```

(It will create two databases: `never-miss-pilates_development` and `never-miss-pilates_test`)

### Running tests:

```console
bundle exec rspec
```

### Run linters on commited changes (autofix with -a):

```console
bundle exec rails linters -a
```

### Starting the server:

Make sure you have `postgres` and `redis` running.

You can use foreman to start the server so you don't have to start sidekiq in a different terminal:

```console
foreman start -f Procfile.dev
```

Then access the API on [http://0.0.0.0:5100](http://0.0.0.0:5100)

### Heroku setup:

For the CLT gym, booking relies on the [heroku-buildpack-chrome-for-testing](https://github.com/heroku/heroku-buildpack-chrome-for-testing). Add it with:

```ruby
heroku buildpacks:add -i 1 heroku-community/chrome-for-testing -a never-miss-pilates
```

### Debugging helpers

- It has new relic setup with structured logging so every step is logged and can be tracked.
- Error are reported into Bugsnag with custom tracing of important decisions to ease debugging. 

---

⚠️ NOTE: Currently the CLT booking is not running because I'm not attending anymore. 
