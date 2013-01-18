# coding: utf-8
require 'sunflower'

class Sunflower
	alias old_API API
	def API *a, &b
		begin
			old_API *a, &b
		rescue
			puts 'API:',$!
			sleep 5
			old_API *a, &b
		end
	end
end



s = Sunflower.new.login

cat = 'Kategoria:Wojsko'
base = "action=query&list=categorymembers&cmprop=title&cmlimit=5000&cmtype=subcat&cmtitle="

queue = [cat]
cats = []

while now = queue.shift
	unless cats.include? now
		cats << now
		puts now
	else
		puts 'repeat ! '+now
	end
	queue += s.API(base+CGI.escape(now))['query']['categorymembers'].map{|v| v['title']}
end

