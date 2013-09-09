# coding: utf-8
require 'sunflower'

def quicksave what, where
	begin
		File.open("#{where}-mar", 'wb'){|f| f.write Marshal.dump what}
		return what
	rescue
		return nil
	end
end

def quickload where
	begin
		what = Marshal.load File.binread "#{where}-mar"
		return what
	rescue
		return nil
	end
end

line_re = /
	(?:
		^\#+ \s* '{0,3}  # list item
		| # or
		\| \s* [\d.]+ \s+ \| \s* # table row
	)
	\[\[ (.+?) (?:\]\]|\|) # link
	| # or
	^(==+[^=]+==+) # heading
/x
uwagi_re = / # dot doesn't match newline - \s does
	\|- \s+
	\| .+ \s+ # lp
	\| .+ \s+ # tytuł
	\| (.+) \s+ # ang
	\| .+ \s+ # długość
	\| .+ \s+ # status
	\| .+ \s+ # medale
	\| (.+) \s+ # uwagi
	\| (.+) \s+ # data
/x

translation_table = Hash[ File.readlines('naglowki-en.txt').map(&:strip).zip File.readlines('naglowki-pl.txt').map(&:strip) ]


# in lists, links are strings/nil, headers (with = signs) are symbols

en = quickload(:en) or begin
	s = Sunflower.new 'meta'
	base = 'List of articles every Wikipedia should have'

	p = s.page base
	
	en = []
	p.text.scan(line_re){|link, header|
		if header
			en << header.to_sym unless header=~/How to use this list/
		else
			en << link.sub(/^en:/, '')
		end
	}

	quicksave en, :en
end

pl = quickload(:pl) or begin
	s = Sunflower.new 'w:en'
	puts 'Mapping interwiki...'
	pl = en.map.with_index{|a, i|
		puts i
		if a.is_a? Symbol
			(a.to_s.sub(/\A(=+)([^=]+)\1\Z/){"#{$1} #{translation_table[$2.strip]} #{$1}"}).to_sym
		else
			resp = s.API("action=query&prop=langlinks&format=json&lllimit=max&titles=#{CGI.escape a}")
			resp['query']['pages'].values[0]['langlinks'].find{|h| h['lang'] == 'pl'}['*'] rescue nil
		end
	}
	puts 'done.'

	quicksave pl, :pl
end





s = Sunflower.new('w:pl').login

uwagi_hash = {}
p = s.page 'Wikipedia:Strony, które powinna mieć każda Wikipedia'
p.text.scan(uwagi_re) do |entitle, uwagi, data|
	entitle, uwagi, data = entitle.strip, uwagi.strip, data.strip
	uwagi_hash[entitle] = uwagi unless ['', 'przekierowanie?', 'interwiki-link do sekcji!'].include? uwagi
end



cats_to_icons = {
	'Artykuły na medal' => 'Plik:Wikimedal alt1.svg',
	'Dobre artykuły' => 'Plik:Propozycja DA.svg',
	'Artykuły do zintegrowania' => 'Plik:Mergefrom.svg',
	'Linki wewnętrzne do dodania' => 'Plik:Wikitext.svg',
	'Artykuły wymagające dopracowania' => 'Plik:DoPracowania.jpg',
	'Artykuły niezgodne z normami polskiego języka literackiego' => 'Plik:DoPracowania.jpg',
	'Artykuły wymagające poprawy stylu' => 'Plik:DoPracowania.jpg',
	'Szablon dopracować bez podanych parametrów' => 'Plik:DoPracowania.jpg',
	'Artykuły wymagające neutralnego ujęcia tematu' => 'Plik:Nuvola apps cache.png',
}

intro = "{| class='wikitable' style='width:100%'
! Lp.
!style='width:20%'| Tytuł
!style='width:15%'| Ang. tytuł
! Długość
! Status
!style='width:20%'| Medal/dobry w innych jęz.?
!style='width:30%'| Uwagi
! Data
"

out = File.open('kanon.txt', 'w')
out.sync = true

headersalready = 0
pairs = en.zip(pl)
puts 'Scanning articles...'
pairs.each_with_index do |pair, i|
	entitle, title = *pair
	
	lp = i - headersalready + 1
	headersalready += 1 if title.is_a? Symbol
	
	puts lp
	
	if title.is_a? Symbol
		# heading
		out.puts '|}' unless i==0 or pl[i-1].is_a? Symbol # don't insert table if consec. headers
		out.puts title
		out.puts intro unless pl[i+1].is_a? Symbol
	elsif !title
		# no page on plwiki
		out.puts "|-
		| #{lp}.
		| ?
		| [[:en:#{entitle}]]
		| 
		| 
		| 
		| #{uwagi_hash[ "[[:en:#{entitle}]]" ] }
		| #{Time.now.strftime '%Y-%m-%d'}
		".gsub '		', ''
	elsif title.include? '#'
		# interwiki to section
		out.puts "|-
		| #{lp}.
		| [[#{title}]]
		| [[:en:#{entitle}]]
		| 
		| 
		| 
		| #{uwagi_hash[ "[[:en:#{entitle}]]" ] || 'interwiki-link do sekcji!' }
		| #{Time.now.strftime '%Y-%m-%d'}
		".gsub '		', ''
	elsif !(cats = (s.make_list 'categories_on', title rescue nil))
		# ours is a redirect?
		out.puts "|-
		| #{lp}.
		| [[#{title}]]
		| [[:en:#{entitle}]]
		| 
		| 
		| 
		| #{uwagi_hash[ "[[:en:#{entitle}]]" ] || 'przekierowanie?' }
		| #{Time.now.strftime '%Y-%m-%d'}
		".gsub '		', ''
	else
		# all seems fine
		p = s.page title
		
		ikonki = cats.map{|cat|
			cat = cat.sub(/\AKategoria:/,'')
			if cats_to_icons[cat]
				"#{cats_to_icons[cat]}|20x20px|#{cat}"
			else
				nil
			end
		}.uniq.compact
		if p.text =~ /\{\{[źŹ]ródła|\{\{[dD]opracować\|.+?(?:źródła|WER)/i
			ikonki << 'Plik:Nuvola kdict glass.png|20x20px|Źródła/WER'
		end
		
		fa = p.text.scan(/\{\{link FA\|(.+?)}}/i).map{|lng| [lng[0], p.text.scan(/\[\[#{lng[0]}:(.+?)\]\]/)[0][0] ] rescue puts title, lng }.compact
		ga = p.text.scan(/\{\{link GA\|(.+?)}}/i).map{|lng| [lng[0], p.text.scan(/\[\[#{lng[0]}:(.+?)\]\]/)[0][0] ] rescue puts title, lng }.compact
		ga -= fa # never display links twice
		
		
		kilobytes = p.text.length.to_f/1024
		kilobytes_style = 
			case kilobytes
			when 0..5; 'color:#800; font-weight:bold'
			when 5..10; 'color:#800'
			when 10..50; nil
			when 50..100; 'color:#080'
			when 100..9999; 'color:#080; font-weight:bold'
			end
		;
		
		out.puts "|-
		| #{lp}.
		| [[#{title}]]
		| [[:en:#{entitle}]]
		|#{kilobytes_style and "style='#{kilobytes_style}'|"} #{("%.1f" % kilobytes).gsub '.', ','}&nbsp;KB
		| #{ikonki.map{|a| "[[#{a}]]"}.join ' '}
		| #{fa.empty? ? '—' : fa.map{|lng, tt| "[[:#{lng}:#{tt}|#{lng}]]"}.join(', ')} / #{ga.empty? ? '—' : ga.map{|lng, tt| "[[:#{lng}:#{tt}|#{lng}]]"}.join(', ')}
		| #{uwagi_hash[ "[[:en:#{entitle}]]" ] }
		| #{Time.now.strftime '%Y-%m-%d'}
		".gsub '		', ''
	end
end

out.puts '|}'
out.close


if ARGV[0]=='--upload'
	text = File.binread('kanon.txt').force_encoding('utf-8').strip
	s.summary = 'automatyczna aktualizacja danych'
	p = s.page 'Wikipedia:Strony, które powinna mieć każda Wikipedia'
	p.text = p.text.sub(
		/(<!-- POCZĄTEK LISTY - nie usuwaj tej linii -->)([\s\S]+?)(<!-- KONIEC LISTY - nie usuwaj tej linii -->)/,
		"\\1\n#{text}\n\\3"
	)
	p.save
	puts "Uploaded."
else
	puts "Didn't upload. (use --upload)"
end
