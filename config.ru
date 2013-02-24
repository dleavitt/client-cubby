require "./app"

map "/" do
  run ClientCubby::App
end

map "/assets" do
  run ClientCubby::App.assets
end