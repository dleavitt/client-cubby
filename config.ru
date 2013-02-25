require "./app"

map "/" do
  run ClientCubby::App
end

map "/assets" do
  run ClientCubby.asset_server(ClientCubby::App.root)
end