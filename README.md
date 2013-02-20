# Client Cubby

I need an FTP!

## Setup

- install rbenv
- install jruby 1.7
- install redis
- copy `config/env.sample.yml` to `config/env.yml` and fill it in
- run: `bundle install`
- run: `rake create_user[root]` - note the generated password

## Run

- the server: `rackup`
- repl: `pry`
- tasks: `rake -T`

try prefixing the commands with `bundle exec` if they don't work

## Data Model

- `STRING user:$name $password`
  account

- `LIST user:$name:files`
  list of file ids for each account

- `HASH files:$id`
  - path
  - name
  - timestamp
  - status

## TODO

- retrieve the files
- ui
- security
- tests

## Screens
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