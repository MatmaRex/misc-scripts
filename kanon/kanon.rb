# coding: utf-8
require 'sunflower'

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

puts 'Loading list...'
s = Sunflower.new 'meta'
base = 'List of articles every Wikipedia should have'

p = s.page base

d = []
p.text.scan(line_re){|link, header|
	if header
		d << header.to_sym unless header=~/How to use this list/
	else
		d << link.sub(/^d:/, '')
	end
}


puts 'Mapping interwiki...'
s = Sunflower.new 'https://www.wikidata.org'
wikidata = {} # used later
pl = d.each_slice(50).map{|ids|
	wikidata.sunflower_recursive_merge! s.API(
		action: 'wbgetentities',
		props: 'sitelinks',
		ids: ids.reject{|a| a.is_a? Symbol }.join('|'),
	)

	ids.map{|a|
		if a.is_a? Symbol
			(a.to_s.sub(/\A(=+)([^=]+)\1\Z/){"#{$1} #{translation_table[$2.strip]} #{$1}"}).to_sym
		else
			wikidata['entities'][a.upcase]['sitelinks']['plwiki']['title'] rescue nil
		end
	}
}.flatten



s = Sunflower.new('w:pl').login

uwagi_hash = {}
p = s.page 'Wikipedia:Strony, które powinna mieć każda Wikipedia'
p.text.scan(uwagi_re) do |entitle, uwagi, data|
	entitle, uwagi, data = entitle.strip, uwagi.strip, data.strip
	uwagi_hash[entitle] = uwagi unless ['', 'przekierowanie?', 'interwiki-link do sekcji!'].include? uwagi
end



cats_to_icons = {
	'Artykuły na medal' => 'Plik:Wikimedal POL.svg',
	'Dobre artykuły' => 'Plik:Propozycja DA.svg',
	'Artykuły do zintegrowania' => 'Plik:Mergefrom.svg',
	'Linki wewnętrzne do dodania' => 'Plik:OOjs UI icon link-ltr.svg',
	'Artykuły wymagające dopracowania' => 'Plik:Broom icon.svg',
	'Artykuły niezgodne z normami polskiego języka literackiego' => 'Plik:Broom icon.svg',
	'Artykuły wymagające poprawy stylu' => 'Plik:Broom icon.svg',
	'Szablon dopracować bez podanych parametrów' => 'Plik:Broom icon.svg',
	'Artykuły wymagające neutralnego ujęcia tematu' => 'Plik:Unbalanced scales lighter one blue.svg',
}

intro = "{| class='wikitable' style='width:100%'
! Lp.
!style='width:20%'| Tytuł
!style='width:15%'| Wikidane
! Długość
! Status
!style='width:20%'| Medal/dobry w innych jęz.?
!style='width:30%'| Uwagi
! Data
"

out = File.open('kanon.txt', 'w')
out.sync = true

headersalready = 0
pairs = d.zip(pl)
puts 'Scanning articles...'
pairs.each_with_index do |pair, i|
	datatitle, title = *pair

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
		| [[:d:#{datatitle}]]
		|
		|
		|
		| #{uwagi_hash[ "[[:d:#{datatitle}]]" ] }
		| #{Time.now.strftime '%Y-%m-%d'}
		".gsub '		', ''
	elsif title.include? '#'
		# interwiki to section
		out.puts "|-
		| #{lp}.
		| [[#{title}]]
		| [[:d:#{datatitle}]]
		|
		|
		|
		| #{uwagi_hash[ "[[:d:#{datatitle}]]" ] || 'interwiki-link do sekcji!' }
		| #{Time.now.strftime '%Y-%m-%d'}
		".gsub '		', ''
	elsif !(cats = (s.make_list 'categories_on', title rescue nil))
		# ours is a redirect?
		out.puts "|-
		| #{lp}.
		| [[#{title}]]
		| [[:d:#{datatitle}]]
		|
		|
		|
		| #{uwagi_hash[ "[[:d:#{datatitle}]]" ] || 'przekierowanie?' }
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
			ikonki << 'Plik:Question book-4.svg|20x20px|Źródła/WER'
		end

		badges = wikidata['entities'][datatitle.upcase]['sitelinks'].values
			.select{|o| o['site'] != 'plwiki' && !o['badges'].empty? }
			.map{|o| o['_language'] = o['site'].sub(/wiki$/, '').gsub('_','-'); o }
		fa = badges.select{|o| o['badges'].include? 'Q17437796' }
			.map{|o| [ o['_language'], o['title'] ] }
		ga = badges.select{|o| o['badges'].include? 'Q17437798' }
			.map{|o| [ o['_language'], o['title'] ] }
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
		| [[:d:#{datatitle}]]
		|#{kilobytes_style and "style='#{kilobytes_style}'|"} #{("%.1f" % kilobytes).gsub '.', ','}&nbsp;KB
		| #{ikonki.map{|a| "[[#{a}]]"}.join ' '}
		| #{fa.empty? ? '—' : fa.map{|lng, tt| "[[:#{lng}:#{tt}|#{lng}]]"}.join(', ')} / #{ga.empty? ? '—' : ga.map{|lng, tt| "[[:#{lng}:#{tt}|#{lng}]]"}.join(', ')}
		| #{uwagi_hash[ "[[:d:#{datatitle}]]" ] }
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
