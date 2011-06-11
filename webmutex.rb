# very quick and very dirty

require 'sinatra'
require 'haml'

# Store hash for requested resoruces. Resource is the key. If value is nil
# I make a new mutex and store it there. Any other requests for that
# resource will attempt to lock that mutex

enable :sessions

Resources = {}

get "/" do
  haml :requestResource
end

#
# Grab a mutex. If one doesn't exist yet, we'll create it to live forever
# more, until someone hits control-c
#

post "/request" do
  requestedResource = params[:resource]
  if nil != session[:holdingResource]
    redirect to "/release"
  end
  if nil == Resources[requestedResource]
    Resources[requestedResource] = Mutex.new
  end
  mutex = Resources[requestedResource]
  mutex.lock
  session[:holdingResource] = requestedResource
  redirect to requestedResource
end

#
# Explicit mutex release (For great justice.) The mutex will also be unlocked
# if our thread goes away. This could happen if the session times out
# or exits (for so-so justice.)
#

get "/release" do
  resource = "(none)"
  if nil != session[:holdingResource]
    resource = session[:holdingResource]
    mutex = Resources[resource]
    if nil != mutex
      if mutex.locked?
        mutex.unlock # If it's your thread you'll get an error
      end
      session[:holdingResource] = nil
    else
      session[:holdingResource] = nil
    end
  end
  "Released mutex for " + resource
end
