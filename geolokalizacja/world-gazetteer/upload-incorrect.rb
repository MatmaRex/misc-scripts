# coding: utf-8

require 'pp'

require 'sunflower'
s = Sunflower.new.login

# macuki = s.make_list 'linkson', 'Wikipedysta:Powerek38/macuk'
macuki = s.make_list 'linkson', 'Wikipedysta:Matma Rex/world-gazetteer'
macuki.shift 11


coords = Marshal.load File.binread 'baza-marshal'
dictionary = Marshal.load File.binread 'dict-marshal'

# Input: array of strings, valid arguments to {{coords}}
# Output: decimal latitude and longitude, as possibly negative floats
def parse_coords args
	lat__ = lon__ = nil
	cur = 0
	mult = 1
	
	args.each do |a|
		next if a.strip==''
		
		if %w[N E S W].include? a
			case a
				when 'N'; lat__ = cur
				when 'S'; lat__ = -cur
				when 'E'; lon__ = cur
				when 'W'; lon__ = -cur
			end
			mult = 1
			cur = 0
		else
			cur += mult * a.to_f
			mult = mult.quo 60
		end
	end
	
	return lat__.to_f, lon__.to_f
end

require './../../infobox parser/infobox parser'

list = Page.new 'User:Matma Rex/world-gazetteer'
list.text = ''

coords.each do |(city, subdiv, country), (lat, long)|
	city_t, subdiv_t, country_t = * dictionary.values_at(city, subdiv, country)
	next if !city_t
	# next unless city_t == 'Szybenik'
	next unless macuki.include? city_t
	
	puts ''
	puts [city_t, subdiv_t, country_t].join ', '
	
	p = Page.new city_t
	
	summary = []
	
	ibox = Infobox.find_in_text p.text
	
	
	previous = nil
	
	if ibox
		# pp ibox
		puts 'Jest infobox.'
		if (ibox['stopniN'] && ibox['stopniN'].strip!='') or (ibox['stopniS'] && ibox['stopniS'].strip!='')
			puts 'Już są koordynaty.'
			
			lat_dir = (ibox['szerokość'] and ibox['szerokość'].strip!='') ? ibox['szerokość'] : nil
			lon_dir = (ibox['długość'] and ibox['długość'].strip!='') ? ibox['długość'] : nil
			
			lat_dir ||= (ibox['stopniN'] and ibox['stopniN'].strip!='') ? 'N' : 'S'
			lon_dir ||= (ibox['stopniE'] and ibox['stopniE'].strip!='') ? 'E' : 'W'
			
			lat_all = %w[stopniN minutN sekundN stopniS minutS sekundS].map{|para| ibox[para]}.compact.select{|a| a.strip!=''}
			lon_all = %w[stopniE minutE sekundE stopniW minutW sekundW].map{|para| ibox[para]}.compact.select{|a| a.strip!=''}
			
			previous = "{{koordynaty|#{(lat_all + [lat_dir]).join('|')}|#{(lon_all + [lon_dir]).join('|')}}}"
			
			%w[stopniN minutN sekundN stopniE minutE sekundE stopniS minutS sekundS stopniW minutW sekundW].each do |para|
				ibox[para] = ''
			end
		end
	end
	
	puts previous
	
	if p.text =~ /\{\{[kK]oordynaty/
		puts 'Już są {{koordynaty}}.'
		
		previous = p.text.match(/\{\{[kK]oordynaty.+?\}\}/)[0]
		p.text.sub! previous, ''
	end
	
	if p.text =~ /\{\{disambig\}\}/i
		puts 'Disambig.'
		next
	end
	
	old, new = nil
	new = * parse_coords("#{lat.to_f.to_s}|#{lat[-1]}|#{long.to_f.to_s}|#{long[-1]}".split("|"))
	if previous
		old = * parse_coords(previous.scan(/[NESW\d.-]+/))
		
		# jesli roznica <= N sekund, to nie zmieniamy
		# puts (old[0] - new[0]).abs
		# puts (old[1] - new[1]).abs
		
		if (old[0] - new[0]).abs < 120.0/3600 and (old[1] - new[1]).abs < 120.0/3600
			puts 'Close enough.'
			next
		end
	end
	
	p old
	p new
	
	ok = 0
	if country_t and  p.text.include? country_t
		ok += 1
	end
	if subdiv_t and  p.text.include? subdiv_t
		ok += 1
	end
	
	if ok == 0
		puts 'Nie pasuje? / Brak danych o państwie/jednostce adm.'
		next
	elsif ok >= 1
		puts 'Pasuje.'
		
	
		summary << 'poprawa błędnie wpisanych koordynatów na podstawie world-gazetteer.com'
		
		if ibox
			if ibox.name !~ /^Miasto/i
				puts 'Niespodziewany infobox!'
				next
			end
			
			kill = %w[stopniN minutN sekundN stopniS minutS sekundS stopniE minutE sekundE stopniW minutW sekundW]
			kill.each{|para| ibox[para] = '' unless ibox[para].to_s.strip=='' }
			
			ibox["stopni#{lat[-1]}"] = lat.to_f.to_s
			ibox["stopni#{long[-1]}"] = long.to_f.to_s
			
			summary << "+sprzątanie infoboksu"
			
			p.text.sub!(
				/#{Regexp.escape Infobox.extract_ib_from_text(p.text)}\s*/, 
				ibox.pretty_format(
					param_order: ibox.keys # on Ruby 1.9+ hashes keep their order
				).gsub(/ \| stopni. =  \| minut. =  \| sekund. = \r?\n/, '') + "\n"
			)
		else
			tpl = "{{koordynaty|#{lat.to_f.to_s}|#{lat[-1]}|#{long.to_f.to_s}|#{long[-1]}}}"
			
			# wstawiamy przed kategoriami
			index = p.text =~ /\{\{DEFAULTSORT|\[\[(kategoria|category)/i
			if !index
				puts 'Nie ma kategorii!'
				next
			else
				p.text[index, 0] = tpl+"\n\n"
			end
		end
	end
	
	# list.append(
		# "* Do zmiany: [[#{p.title}]]: " +
		# (old ? "{{koordynaty|umieść=w tekście|#{old.join '|'}}}" : '')+
		# " -> "+
		# "{{koordynaty|umieść=w tekście|#{new.join '|'}}}",
	# 1)
	# list.dump
	
	# p.dump
	p.save p.title, summary.join(", ")
	puts 'Zapisano zmiany.'
	# gets
end

# s.summary = 'lista zmian do wykonania'
# list.save

