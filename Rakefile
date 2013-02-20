desc "Loads the app environment"
task :env do
  require "./app"
end

desc "Wipes redis. Use with care!"
task :wipe => [:env] do
  $redis.keys("*").map { |k| $redis.del(k) and puts "Deleted #{k}" }
end

desc "Create a new user"
task :create_user, [:name] => [:env] do |t,args|
  user = ClientCubby::User.create(args[:name])
  puts "Created user '#{user.name}' with password '#{user.password}'"
end