require 'bundler/setup'
Bundler.require()
require './app/app'

# Replace the directory names to taste
use Rack::Static, :urls => ['/css', '/js', '/img', 'images', '/fonts', '/content/font'], :root => 'public'

run App
