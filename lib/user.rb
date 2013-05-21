module ClientCubby
  class User

    attr_reader :name

    def self.create(name, password = nil)
      raise "Invalid User Name" unless name && name[/[\w\d-]+/] 
      
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
      file_ids = $redis.smembers files_ns
      $redis.pipelined { |r| file_ids.map { |id| r.hgetall(file_ns(id)) } }
        .sort_by { |f| f["timestamp"] }.reverse
    end

    def find_file(file_id)
      hsh = $redis.hgetall file_ns(file_id)
      hsh.empty? ? nil : hsh
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
      $redis.mapped_hmset file_ns(file_id), attributes
    end

    def delete_file(file_id)
      $redis.srem files_ns, file_id
      $redis.del file_ns(file_id)
    end

    def file_ns(filename)
      "#{files_ns}:#{filename}"
    end

    def files_ns
      "#{ns}:files"
    end

    def ns
      "users:#{name}"
    end
  end
end
