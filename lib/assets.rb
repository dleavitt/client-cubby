module ClientCubby
  def self.asset_server(root)
    sprockets = Sprockets::Environment.new(root)
    # precompile = [ /\w+\.(?!js|css).+/, /application.(css|js)$/ ]

    # Set up Sprockets
    %w(javascripts stylesheets images).each do |subdir|
      sprockets.append_path File.join(root, 'assets', subdir)
      sprockets.append_path File.join(root, 'vendor', 'assets', subdir)
      %w(vendor lib app).each do |base_dir|
        # load for all gems
        Gem.loaded_specs.map(&:last).each do |gemspec|
          path = File.join(gemspec.gem_dir, base_dir, "assets", subdir)
          sprockets.append_path path if File.directory? path
        end
      end
    end

    Sprockets::Helpers.configure do |config|
      config.environment = sprockets
      config.prefix      = "/assets"
      config.digest      = true
      config.public_path = "/public"
    end

    Sprockets::Sass.add_sass_functions = true

    return sprockets
  end
end