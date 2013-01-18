# coding: utf-8

require 'sunflower'
s = Sunflower.new 'en.wikipedia.org'

coords = Marshal.load File.binread 'baza-marshal'

dictionary = {}

# znajdz po interwiki polskie nazwy terytoriow i panstw
# coords.keys.map{|a| a.values_at(1,2)}.flatten.uniq.compact.each_slice(30) do |territs|
coords.keys.flatten.uniq.compact.each_slice(30) do |territs|
	res = s.API action:'query', prop:'langlinks', lllimit:500, titles:territs.join('|')
	next if res.empty?
	
	res['query']['pages'].each_with_index do |(id, val), i|
		pl_tt = nil
		if val and val['langlinks']
			pl_tt = val['langlinks'].find{|h| h['lang'] == 'pl'}
			pl_tt = pl_tt['*'] if pl_tt
		end
		
		next if !pl_tt
		
		dictionary[val['title']] = pl_tt
		puts "#{val['title']} - #{pl_tt}"
	end
	
end

File.binwrite 'dict-marshal', Marshal.dump(dictionary)
