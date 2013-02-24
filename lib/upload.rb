module ClientCubby
  class Upload

    attr_accessor :id, :name, :timestamp

    class << self
      attr_accessor :bucket_name
    end

    def initialize(id, attributes = {})
      @id = id
      @name = attributes["name"]
      @timestamp = attributes["timestamp"]

      @file = attributes[:file]
    end

    def get
      url = s3_object.url_for :read,
        :force_path_style => true,
        :expires => 10,
        :response_content_disposition => "attachment; filename=\"#{@name}\""
      url.to_s
    end

    def put
      puts @id
      s3_object.write(@file)
      s3_object.acl = :private
    end

    def delete
      s3_object.delete
    end

    def s3_object
      AWS::S3.new.buckets[self.class.bucket_name].objects[@id]
    end

  end
end