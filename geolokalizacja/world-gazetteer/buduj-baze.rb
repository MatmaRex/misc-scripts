# coding: utf-8

require 'rest-client'
require 'nokogiri'

noko = Nokogiri.parse RestClient.get 'http://world-gazetteer.com/'
ids = noko.css('#selcountry select option').map{|o| o['value']}

coords = {}

ids.sort.uniq.each do |id|
	noko = Nokogiri.parse RestClient.get "http://world-gazetteer.com/wg.php?x=&men=gcis&lng=en&des=wg&srt=npan&col=abcdefghinoq&msz=1500&geo=#{id}"
	
	country = noko.at('#navig2').at('a').text.strip
	country = nil if %w[0 -1 -2 -3 -4 -5].include? id # kontynenty...
	
	headings = noko.css('table[summary] tr th').map{|h| h.text.strip}
	
	name_idx = headings.index 'name'
	parent_idx = headings.index 'parent division'
	country_idx = headings.index 'country'
	lat_idx = headings.index 'latitude'
	long_idx = headings.index 'longitude'
	
	puts "#{country} - #{[name_idx, parent_idx, country_idx, lat_idx, long_idx].inspect}"
	
	rows = noko.css('table[summary] tr:not(:first-child)')
	rows.each do |row|
		cells = row.css('td').map{|a| a.text.strip}
		
		name = cells[name_idx]
		parent = parent_idx && cells[parent_idx]
		country ||= country_idx && cells[country_idx]
		
		lat, long = *cells.values_at(lat_idx, long_idx)
		
		next if lat=='' or long==''
		
		key = [name, parent, country]
		value = [lat, long]
		
		if coords[ key ]
			puts "dupe; k=#{key.inspect}, same? #{coords[key]} vs #{value}"
		else
			coords[key] = value
		end
	end
end

File.binwrite 'baza-marshal', Marshal.dump(coords)
