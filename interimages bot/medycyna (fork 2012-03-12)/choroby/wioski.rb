# coding: utf-8
# by Matma Rex
# matma.rex@gmail.com
# released under CC-BY-SA 3.0

require 'sunflower'
require './get-images.rb'

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



s = Sunflower.new 'pl.wikipedia.org'
s.warnings = false
s.login



if File.exist? 'list-marshal'
	list = Marshal.load File.open('list-marshal','rb'){|f| f.read}
else
	list = s.make_list 'category-r', 'Kategoria:Choroby'
	list.delete_if{|a| a.start_with? 'Kategoria:'}
	
	File.open('full-list-marshal','wb'){|f| f.write Marshal.dump list.dup}
end

puts "List: #{list.length}"



results={}
if File.exist? 'results-marshal'
	results.merge! Marshal.load File.open('results-marshal','rb'){|f| f.read}
end




# save everything every five minutes
savethread=Thread.new do
	loop do
		File.open('list-marshal','wb'){|f| f.write Marshal.dump list.dup}
		File.open('results-marshal','wb'){|f| f.write Marshal.dump results.dup}
		sleep 300
	end
end


threads = []
5.times do
	threads<<Thread.new do
		begin
			until list.empty?
				name = list.shift
				images, interwikimap = get_images 'pl', name
				
				results[name]=[images, interwikimap]
				puts list.length
			end
		rescue
			puts $!, $!.backtrace
		
			list.unshift name
			sleep 20
			retry
		end
	end
end
threads.each &:join

savethread.kill

File.open('list-marshal','wb'){|f| f.write Marshal.dump list.dup}
File.open('results-marshal','wb'){|f| f.write Marshal.dump results.dup}

