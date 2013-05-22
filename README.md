# Client Cubby

I need an FTP!

## Setup

- install rbenv
- install ~~jruby 1.7~~ ruby 1.9.3
- install redis
- copy `config/env.sample.yml` to `config/env.yml` and fill it in
- run: `gem install bundler`
- run: `bundle install`
- run: `rake create_user[root]` - note the generated password

## Run

- the server: `rackup` (app will be available at [http://localhost:9292](http://localhost:9292))
- repl: `pry`
- tasks: `rake -T`

try prefixing the commands with `bundle exec` if they don't work

prefix them with `heroku run` to run them on Heroku (assuming you've been added as a collaborator.)
For instance, you can add a new user to the app like so: 

      $ heroku run rake create_user[clientname] -a client-cubby
      
Be sure to note the generated password!

## Deploy


Add Heroku as a remote:

      $ git remote add heroku git@heroku.com:client-cubby.git

Deploy it:

      $ git push heroku master 

Run stuff:
      
      $ heroku run rake console
      $ heroku run rake create_user[clientname]
      
Suffix with `-a client-cubby` if you're not in the app directory. 
See also: http://wiki.hyfnrsx1.com/wiki/heroku-deployment#Useful-Heroku-commands

## Data Model

- `STRING users:$name` password
- `SET users:$name:files`
- `HASH users:$name:files:$file_id`
  - path
  - name
  - timestamp
  - status

## TODO

- multi-file upload
- IE feature detection / fallback
- tests
- newrelic
- better way to set accounts (google doc?)

## Features
- File List
    - File type icon
    - File name
    - Download link
    - Copyable URL
    - Share button
    - Big place at the bottom to drop a file
- `GET /u/:username/:file_id`
  Download splash for the file
- Special root page that shows all files
- Secret link to file that bypasses u/p
- Copy to clipboard
