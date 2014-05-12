require 'sinatra'
require 'net/http'
require 'nokogiri'
require 'mustache'
require 'open-uri'
require './parser'

get '/mobile' do
	erb :mobile
end
	
post '/add' do
	name = params[:name]

	mobile_page = Extractor.new(name).render if $0 == __FILE__
	File.open('./views/mobilePage.erb', 'w') do |item|
	  item.puts mobile_page
	end  	 
end

get '/mobilePage' do
	erb :mobilePage
end

get '/down/:page' do |page|
	file = File.join('./', page)
	send_file(file, :disposition => 'attachment', :filename => File.basename(file))
end










