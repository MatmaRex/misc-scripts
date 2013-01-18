# coding: utf-8

# fix dla 1.9.1 i wcześniejszych
# niepełna funkcjonalność, ale wystarczy
unless [].respond_to? :chunk
	class Array
		def chunk
			ret = []
			prev = nil
			
			self.each do |el|
				now = yield el
				
				if now != prev
					ret.push [now, []]
					prev = now
				end
				
				ret.last.last<<el
			end
			
			ret
		end
	end
end


require 'sunflower'
require 'memoize'

class Sunflower; include Memoize; end

s = Sunflower.new.login
s.memoize :make_list, 'tmp-memo'


case ARGV[0]
when '--make'
	a = s.make_list 'category-r', 'Kategoria:Pseudonauka'

	where = {}

	res = a.map.with_index do |name, i|
		puts "#{i}/#{a.length}"

		p = Page.new name
		sc = p.text.scan(/https?:\/\/\S+/)
		
		sc.each{|link| where[link] = name}
		sc
	end

	Marshal.dump where, File.open('where-marshal', 'w')
	Marshal.dump res, File.open('res-marshal', 'w')

when '--show'
	require 'uri'
	
	kopernik = s.make_list 'category-r', 'Kategoria:Mikołaj Kopernik'

	where = Marshal.load File.open 'where-marshal'
	res = Marshal.load File.open 'res-marshal'
	
	
	# wciągnij wszystko razem
	data = res.flatten.map do |link| 
		
		# regex użyty do znajdywania linków okazuje się być trochę zbyt zachłanny; wywal śmieci z końca linku
		end_of_link = link.index(/[\[\]\|\{\}<>]/)
		real_link = link[end_of_link ? 0...end_of_link : 0..-1]
		
		# domena bez www i pochodnych
		domain = URI.parse(real_link).host.sub(/\Aww[^.]*\./, '') rescue '???'
		
		[domain, real_link, where[link]]
	end
	
	# wywal Kopernika - to powinno być w --make, ale nie chce mi się znowu czekać na przeglądnięcie całej kategorii
	data = data.delete_if{|d,l,w| kopernik.include? w}

	# grupuj wg domen, sortuj wg liczby wystąpień malejąco
	data = data.sort_by{|d,l,w| d}.chunk{|d,l,w| d}.sort_by{|domain, arr| arr.length}.reverse
	
	data = data.map{|domain, arr| 
		(
			["* #{domain} ([[special:linksearch/*.#{domain}|''linksearch'']]) - #{arr.length} wystąpień"] +
			arr.sort_by{|d,l,w| l.split(d)[-1]}.map{|d,l,w| "** #{l} na [[#{w}]]"}
		).join "\n"
	}
	
	puts data

else
	puts %w[--make --show]
end

