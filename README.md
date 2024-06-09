# never-miss-pilates

## Pre requisites

- Postgres
- Redis
- liv (`brew install vips`)
- Ruby (Recommendations: install with `rbenv`)

## Installation

Clone this repository on your local machine.

Install the correct version of ruby that you can find in `.ruby-version` file.
Example with `rbenv` (double-check project ruby version in Gemfile in case it got updated):

```console
rbenv install 3.2.2; rbenv local 3.2.2;
```

### Setup our gems:

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

## Running tests:

```console
bundle exec rspec
```

## Starting the server:

Make sure you have `postgres` and `redis` running.

You can use foreman to start the server so you don't have to start sidekiq in a different terminal:

```console
foreman start -f Procfile.dev
```

Then access the API on [http://0.0.0.0:5100](http://0.0.0.0:5100)


### Running the tasks

Enqueue all the desired bookings jobs with:

```ruby
Enqueuer::Worker.new.perform
```

Attempt a specific desired booking:

```ruby
desired_booking = DesiredBooking.last
Processor.new(desired_booking:).process
```

### Heroku setup:

Relies on the [heroku-buildpack-chrome-for-testing](https://github.com/heroku/heroku-buildpack-chrome-for-testing). Add it with:

```ruby
heroku buildpacks:add -i 1 heroku-community/chrome-for-testing -a never-miss-pilates
```
