# coding: utf-8

require 'sunflower'
s = Sunflower.new.login

syn = s.make_list 'categoryr', 'Kategoria:Synagogi Polski'
cmen = s.make_list 'categoryr', "Kategoria:Cmentarze \u017cydowskie w Polsce"
links = s.make_list 'linksearch', '*.sztetl.org.pl/pl/'
list = (cmen.sort + syn.sort) & links.sort

# list = File.readlines('list.txt').map(&:strip).sort
p list.length



require './../infobox parser/infobox parser'
ibox_syn = Infobox.parse File.open('infobox1.txt', 'r:utf-8'){|f| f.read}
ibox_cme = Infobox.parse File.open('infobox2.txt', 'r:utf-8'){|f| f.read}



list.each do |t|
	puts ''
	
	p = Page.new t
	puts t
	
	summary = []
	
	ibox = Infobox.find_in_text p.text
	if ibox
		puts 'Jest infobox.'
		if ibox.name == 'Synagoga' || ibox.name == 'Cmentarz'
			if ibox['stopniN'] and ibox['stopniE'] and ibox['stopniN'].strip!='' and ibox['stopniE'].strip!=''
				puts 'Już są koordynaty.'
				next
			end
		else
			puts "Niespodziewany infobox #{ibox.name}."
			next
		end
	else
		if p.text =~ /\{\{[kK]oordynaty/
				puts 'Już są koordynaty.'
				next
		end
	end
	
	
	sztetle = p.text.scan(%r|https?://(?:www\.)?sztetl.org.pl/pl/[^\s\[\] ]+|)
	if sztetle.empty?
		puts "Nie ma sztetli?"
		next
	elsif sztetle.length > 1
		puts "Więcej niż 1 link."
		next
	else
		puts 'Jest sztetl.'
		
		res = RestClient.get sztetle[0]
		koord = res.scan(/normalMarker\(([\d.]+), ([\d.]+)\);/)
		if koord.empty?
			puts 'Brak koordynatów na sztetlu.'
			next
		elsif koord.length > 1
			puts 'Wiele koordynatów?'
			next
		else
			lat, long = *koord.first
		end
		
		if lat and long
			lat, long = lat.to_f.round(3), long.to_f.round(3)
			
			summary << 'dodanie koordynatów na podstawie sztetl.org.pl'
			
			if ibox
				ibox['stopniN'] = lat.to_s
				ibox['stopniE'] = long.to_s
				if ibox['państwo'].to_s.strip == ''
					ibox['państwo'] = 'POL'
					summary << "+państwo=POL w infoboksie"
				end
				
				summary << "+sprzątanie infoboksu"
				
				ibox_template = (ibox.name == 'Synagoga' ? ibox_syn : ibox_cme)
				
				p.text.sub!(
					/#{Regexp.escape Infobox.extract_ib_from_text(p.text)}\s*/, 
					ibox.pretty_format(
						reqd_params: ibox_template.keys,
						param_order: ibox_template.keys # on Ruby 1.9+ hashes keep their order
					).gsub(/ \| stopni. =  \| minut. =  \| sekund. = \r?\n/, '') + "\n"
				)
			else
				tpl = "{{koordynaty|#{lat}|N|#{long}|E}}"
				
				# wstawiamy przed kategoriami
				index = p.text =~ /\{\{DEFAULTSORT|\[\[(kategoria|category)/i
				if !index
					puts 'Nie ma kategorii!'
					next
				else
					p.text[index, 0] = tpl+"\n\n"
				end
			end
		else
			puts "Nie odnaleziono koordynatów."
			next
		end
	end
	
	
	# p.dump
	p.save p.title, summary.join(", ")
	puts 'Zapisano zmiany.'
	# gets
end



