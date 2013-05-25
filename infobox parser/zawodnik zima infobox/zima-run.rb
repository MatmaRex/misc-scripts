# coding: utf-8
require 'sunflower'
require 'pp'
require './../infobox parser.rb'

require 'io/console'
print 'Password: '
s = Sunflower.new('pl.wikipedia.org').login('MatmaBot', STDIN.noecho(&:gets).strip)
puts ''

summary = 'regeneracja {{[[Szablon:Zawodnik zima infobox|Zawodnik zima infobox]]}}'

# base = (ARGV[0] ? ARGV[0].to_i : Time.now.to_i)
# srand base
# puts base

def to_param_name str
	str.downcase_pl.strip.gsub(/ +/,' ').gsub(/\[\[(?:[^\|\]]+\|)?([^\]]+)\]\]/, '\1')
end

# s.make_list 'whatembeds', 'Szablon:Zawodnik zima infobox'

api_endpoint = 'action=query&list=embeddedin&eilimit=max&eititle=Szablon:Zawodnik%20zima%20infobox/koniec'
titles = []

res = s.API(api_endpoint)
titles += res['query']['embeddedin'].map{|a| a['title'] }
while res['query-continue']
	res = s.API(api_endpoint + "&eicontinue=#{res["query-continue"]["embeddedin"]["eicontinue"]}")
	titles += res['query']['embeddedin'].map{|a| a['title'] }
end

titles = titles.reject{|t| t.include? 'Wikipedysta:Matma Rex/zawodnik zima - testy' }

p titles.length



titles.each_with_index do |title, i|
	# puts i, title

	p = Page.new title
	p.text = p.text.gsub(/{{Szablon\s*:\s*/i, '{{')
	t = p.text.dup
	
	t.gsub! 'Medalista infobox/nagłówek', 'Zawodnik zima infobox/podrozdział'
	t.gsub! 'medalista infobox/nagłówek', 'Zawodnik zima infobox/podrozdział'
	
	t.gsub! 'Zawodnik  zima infobox', 'Zawodnik zima infobox'
	t.gsub! 'Szablon:', ''

	ib = Infobox.new 'Zawodnik zima'

	# extract name and image
	t.gsub!(/{{Zawodnik zima infobox\|(.+?)}}/i){ib[:zawodnik] = $1.split('|').first.strip; ''}
	t.gsub!(/{{Zawodnik zima infobox\/grafika\|(.+?)}}/i){ib[:grafika] = $1.split('|').first.strip; ''}

	# remove sub-titles in the table
	t.gsub!(/{{Zawodnik zima infobox\/podrozdział\|(.+?)}}\s*(?={{Zawodnik zima infobox\/wiersz)/i, '')
	
	t.gsub!(/{{Zawodnik zima infobox\/koniec}}/i, '')
	t.gsub!(/({{Zawodnik zima infobox\/.+?}})\s*\|\}/i, '\1')

	# extract all the extractable rest
	t.gsub!(/{{Zawodnik zima infobox\/wiersz\|((?:\[\[[^\]]+\]\]|[^\[\|]+)+)\|((?:{{[^}]+}}|[^{}]+)+)}}(.+|)/i){
		param, value = $1, $2+$3
		ib[ to_param_name param ] = value.strip.gsub(/^\||\|$/, '').strip; ''
	}

	# and just keep others.
	list = []
	t.gsub!(/{{Zawodnik zima infobox\/(rozdzia.|podrozdzia.|medal|medal bez|puchar|rekord)\|((?:{{[^}]+}}|[^{}]+)+)}}(.+)?/i){
		a = $&
		b = $3
		
		# napraw refy umieszczone poza szablonami
		a.sub!(/\}\}#{Regexp.escape b}$/, "#{b}}}") if b
		
		list << a.sub('{{zawodnik', '{{Zawodnik'); ''
	}
	
	unless list.empty?
		# split the list based on headings
		chunked = list.chunk{|s| !!(s =~ /\{\{Zawodnik zima infobox\/rozdzia/i) }.to_a
		chunked.unshift([true, ['{{Zawodnik zima infobox/rozdział|Dorobek medalowy}}']]) if chunked[0][0] == false
		
		heading_simplify_map = {
			/rekordy|sprzęt|żeglarstwo/ => :kill,
			
			/mistrzostwa polski|puchar świata/ => :subhead,
			
			/dorobek medalowy \(/ => :dyscyp,
			/biathlon|biegi|biegi narciarskie|kombinacja norweska|narciarski bieg na orientację|narciarstwo alpejskie|ski mountaineering|skoki narciarskie/ => :dyscyp,
			
			/inne/ => 'inne nagrody',
			/odznaczenia/ => 'odznaczenia',
			/osiągnięcia|sukcesy|dorobek medalowy/ => 'dorobek',
		}
		
		killed_records = false
		chunked.each_slice(2) do |(_, heading_text_ary), (__, rows)|
			just_text = heading_text_ary.first.sub('{{Zawodnik zima infobox/rozdział|', '').sub(/\}\}.*$/, '').strip
			heading = to_param_name just_text
			
			puts title if !rows
			next if !rows || rows.empty?
			
			case new_h_maybe = heading_simplify_map.find{|r,v| r =~ heading}[1]
			when String
				ib[new_h_maybe] ||= ''
				ib[new_h_maybe] += "\n" + rows.join("\n")
			when :kill, nil
				killed_records = (heading =~ /rekordy/i)
				# pass
			when :subhead
				rows.unshift "{{Zawodnik zima infobox/podrozdział|#{just_text}}}"
				ib['dorobek'] ||= ''
				ib['dorobek'] += "\n" + rows.join("\n")
			when :dyscyp
				rows.unshift "{{Zawodnik zima infobox/dorobek w dyscyplinie|#{heading.sub(/^dorobek medalowy \((.+?)\)$/, '\1').capitalize}}}"
				ib['dorobek'] ||= ''
				ib['dorobek'] += "\n" + rows.join("\n")
			else
				puts heading
				raise
			end
		end
	end
	
	# regeneration!
	renames = {
		'debiut w pś' => 'debiut pś',
		'debiut w pucharze świata' => 'debiut pś',
		'pierwszy start w konkursie pś' => 'debiut pś',
		'pierwsze punkty w pś' => 'pierwsze punkty pś',
		'pierwsze punkty<br />pś' => 'pierwsze punkty pś',
		'debiut punkty w pś' => 'pierwsze punkty pś',
		'pierwsze podium w pś' => 'pierwsze podium pś',
		'pierwsze podium<br />pś' => 'pierwsze podium pś',
		'pierwsze zwycięstwo w pś' => 'pierwsze zwycięstwo pś',

		'pierwsza wygrana w pś' => 'pierwsze zwycięstwo pś',
		'pierwsze punkty pucharu świata' => 'pierwsze punkty pś',
		'pierwszy występ w konkursie pś' => 'debiut pś',


		'debiut w pś indywidualnie' => 'debiut pś indywidualnie',
		'debiut w pś drużynowo' => 'debiut pś drużynowo',

		'reprezentacje' => 'reprezentacja',
		'reprezentowane kraje' => 'reprezentacja',
		'repreyentacja' => 'reprezentacja',
		'debiut w reprezentacji' => 'debiut reprezentacja',
		'debiut w kadrze narodowej' => 'debiut reprezentacja',

		'oficjalna strona' => 'www',
		'pseudonim' => 'przydomek',
		'przydomki' => 'przydomek',
		'opis zdjecia:' => 'opis grafiki',
		'debiu' => 'debiut',
		'trenerzy' => 'trener',
		'trenerrz' => 'trener',
		'pierwszy trener, trener klubowy' => 'trener',
		'osobisty trener' => 'trener indywidualny',

		'kluby' => 'klub',
		'data ur.' => 'data urodzenia',
		'rok urodzenia' => 'data urodzenia',
		'miejsce ur.' => 'miejsce urodzenia',
		'data urodznia' => 'data urodzenia',
		'miesjce urodzenia' => 'miejsce urodzenia',
		
		'najdłuższy skok' => 'rekord życiowy',
	}
	
	param_order = ['imię i nazwisko', 'grafika', 'opis grafiki', 'data urodzenia', 'miejsce urodzenia', 'data śmierci', 'miejsce śmierci', 'klub', 'wzrost', 'waga', 'przydomek', 'debiut', 'debiut indywidualnie', 'debiut drużynowo', 'pierwsze punkty', 'pierwsze podium', 'pierwsze zwycięstwo', 'reprezentacja', 'debiut reprezentacja', 'rekord życiowy', 'pierwszy trener', 'trener', 'trener kadry', 'trener indywidualny', 'commons', 'wikicytaty', 'www', 'medale', 'inne nagrody', 'odznaczenia']
	reqd_params = ['imię i nazwisko', 'grafika', 'opis grafiki', 'data urodzenia', 'miejsce urodzenia', 'data śmierci', 'miejsce śmierci', 'klub', 'wzrost', 'waga', 'przydomek', 'commons', 'wikicytaty', 'www', 'medale']
	
	# rename parameters
	ib.keys.each do |k|
		if k =~ /1-sze|1\./
			ib[k.sub(/1-sze|1\./, 'pierwsze')] = ib.delete k
		end
	end
	renames.each do |from, to|
		if ib[from]
			ib[to] = ib.delete from
		end
	end
	
	# kill "pś"
	ib.keys.each do |k|
		if k =~ / pś\b/
			ib[k.sub(/ pś\b/, '')] = ib.delete k
		end
	end
	
	ib[:www] &&= (URI.extract ib[:www], %w[http https]).first
	
	ib[:zawodnik] ||= '{{subst:PAGENAME}}'
	
	ib[:odznaczenia] &&= ib[:odznaczenia].gsub(/{{Zawodnik zima infobox\/(?:rozdzia.|podrozdzia.|medal|medal bez|puchar|rekord)\|((?:{{[^}]+}}|[^{}]+)+)}}\s*/, '\1 ')
	ib[:odznaczenia] && ib[:odznaczenia].strip!
	
	if t =~ /\{\{commons(?:all)?(?:\}\}|\|([^\|\}]+))/i
		ib[:commons] = $1 || '{{subst:PAGENAME}}'
	end
	if t =~ /\{\{commonscat(?:\}\}|\|([^\|\}]+))/i
		ib[:commons] ||= 'Category:'+($1 || '{{subst:PAGENAME}}')
	end
	if t =~ /\{\{wikicytaty\|(?:[^\|\}]+)(?:\}\}|\|([^\|\}]+))/i
		ib[:wikicytaty] = $1 || '{{subst:PAGENAME}}'
	end
	
	
	ib['imię i nazwisko'] = ib['zawodnik']
	ib['medale'] = ib['dorobek']
	
	
	# remove fields with no values or unknown
	ib.each_key do |k|
		if !ib[k] or ib[k]=='?' or !(param_order.include? k)
			ib.delete k
		end
	end
	
	opts = {
		param_order: param_order,
		reqd_params: reqd_params,
	}
	
	starttag = /{{Zawodnik +zima +infobox\|/i
	endtag = /{{Zawodnik +zima +infobox\/koniec}}|\r?\n\s*\|\}/i
	
	old = p.text[ p.text.index(starttag) ... (p.text.index(endtag)+$&.length) ] rescue (puts title and '')
	new = ib.pretty_format(opts)
	
	next if old.to_s == ''
	
	p.text = p.text.sub old, new
	p.save p.title, summary + (killed_records ? ' + usunięcie rekordów z infoboksu' : '')
	
	puts "#{i.to_s.rjust 4, '0'} #{title}"
	
	# gets
end

