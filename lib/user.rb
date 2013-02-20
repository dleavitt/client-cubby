module ClientCubby
  class User

    attr_reader :name

    def self.create(name, password = nil)
      password ||= SecureRandom.urlsafe_base64(8)
      user = new(name)
      $redis.set user.ns, password
      return user
    end

    def self.exists?(name, password)
      if name && password
        user = User.new(name)
        user.exists? && user.password == password
      else
        false
      end
    end

    def initialize(name)
      @name = name
    end

    def password
      @password ||= $redis.get ns
    end

    def exists?
      $redis.exists ns
    end

    def all_files
      file_ids = $redis.sadd files_ns
      $redis.pipelined { |r| file_ids.map { |id| r.hgetall(file_ns(id)) } }
    end

    def find_file(file_id)
      $redis.hgetall file_ns(file_id)
    end

    def create_file(filename)
      file_id = SecureRandom.urlsafe_base64
      update_file file_id, :id => file_id,
                           :name => filename,
                           :timestamp => Time.now.to_i,
                           :progress => 0


      $redis.sadd files_ns, file_id
      file_id
    end

    def update_file(file_id, attributes)
      $redis.hmset file_ns(file_id), *attributes.to_a.flatten
    end

    def file_ns(filename)
      "files:#{filename}"
    end

    def files_ns
      "users:#{name}:files"
    end

    def ns
      "users:#{name}"
    end
  end
end