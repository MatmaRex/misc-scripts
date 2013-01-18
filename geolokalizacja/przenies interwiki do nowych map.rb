# coding: utf-8
require 'sunflower'

s = Sunflower.new.login
iwprefixes = s.siteinfo['interwikimap'].select{|h| h['language'] }.map{|h| h['prefix'] }

list = s.make_list 'category', 'Kategoria:Szablony map lokalizacyjnych'

list.pages_preloaded.each do |page|
	next unless page.title.start_with? 'Szablon:Mapa lokalizacyjna/'

	code = page.title[%r|/(.+)|, 1]
	new_page = s.page "Szablon:Mapa dane #{code}"
	
	if !new_page.pageid || new_page.text =~ /stare redirecty/
		puts "skipping #{page.title}"
		next
	end
	
	new_page.preload_attrs
	if new_page.instance_variable_get :@redirect
		new_page = s.page new_page.text[ /\[\[([^\|\]]+)/, 1 ]
	end
	
	puts "#{page.title} -> #{new_page.title}"
	
	interwikis = page.text.scan(/\[\[(?:#{Regexp.union iwprefixes}):.+?\]\]/)
	interwikis += new_page.text.scan(/\[\[(?:#{Regexp.union iwprefixes}):.+?\]\]/)
	
	interwikis = interwikis.sort.uniq
	
	if interwikis.empty?
		puts 'interwikis.empty?'
	else
		new_page.text.gsub! /\[\[(?:#{Regexp.union iwprefixes}):.+?\]\]\s*/, ''
		
		unless new_page.text =~ /\s*<\/noinclude>\s*\z/i
			new_page.text.sub! /\s*\z/, "<noinclude></noinclude>"
		end
		
		new_page.text.sub! /\s*<\/noinclude>\s*\z/i, "\n#{interwikis.join("\n")}\n</noinclude>"
		
		new_page.save new_page.title, "+interwiki"
	end
	
	if s.make_list('whatembeds', page.title).empty?
		page.prepend "{{ek|zastąpione przez [[#{new_page.title}]], brak wywołań}}"
		page.save page.title, "{{ek}}"
	else
		puts "#{page.title} ma wywolania!"
	end
	
	# gets
end
