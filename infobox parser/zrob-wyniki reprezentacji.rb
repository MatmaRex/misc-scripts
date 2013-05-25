# coding: utf-8
require 'sunflower'
require 'pp'
require_relative 'infobox parser'

$mode = ARGV.shift.strip

require 'io/console'
# print 'Password: '
s = Sunflower.new('pl.wikipedia.org').login#('MatmaBot', STDIN.noecho(&:gets).strip)
# puts ''
s.summary = case $mode
	when 'test'; 'test infoboksu'
	when 'commit'; 'regeneracja {{[[Szablon:Wyniki reprezentacji infobox|Wyniki reprezentacji infobox]]}}'
	else; nil
end


# $logfile = File.open('request.log', 'a')
# $logfile.sync = true
# module APILogger
	# def API *a
		# $logfile.puts a
		# super
	# end
# end
# s.singleton_class.send :include, APILogger


def cleaned s, whitelist=%w[ref]
	s ||= ''
	whitelist << '---' # prevent empty (?!) in regexes
	
	s.gsub(/'{2,3}/, '').gsub(/<(?!#{whitelist.join '|'})(?!\/(?:#{whitelist.join '|'}))[^>]+>/, '')
end

sss = "{{Wyniki reprezentacji infobox
 |nazwa                  = ok
 |państwo                = ok
 |wariant flagi = 
 |kod MKOl               = ok
 |kod organizacja        = ok
 |organizacja            = ok
 |impreza z linkiem      = ok
 |miejscowość            = ok
 |chorąży                = ok
 |liczba zawodników      = ok
 |liczba konkurencji     = ok
 |liczba dyscyplin       = ok
 |pozycja w klasyfikacji = ok
 |złote                  = ok
 |srebrne                = ok
 |brązowe                = ok
 |suma                   = ok
}}"




# titles = s.make_list('linkson', 'Wikiprojekt:Sprzątanie szablonów/źle wstawione infoboksy/olimpiady').grep(/\d{4}\z/)
titles = s.make_list('grep', '^.+ na (Igrzyskach|Mistrzostwach) .+ [0-9]{4}$') - s.make_list('usercontribs', 'MatmaBot')

titles = titles.reject{|t| t.include? 'Wikipedysta:Matma Rex/Wyniki reprezentacji infoboxy' }

p titles.length



stats = []

if $mode == 'stats'
	trap("INT") do
		File.write 'stats.txt', <<-EOF.gsub(/^\t+/, '').strip
			{| class="wikitable sortable"
			! Państwo !! Rok !! Flaga stara !! Flaga nowa !! Artykuł
			#{
				stats.sort_by{|title, iso, year, flag, variant| [iso, year, title] }.map{|title, iso, year, flag, variant|
					<<-EOFF.gsub(/^\t+/, '').strip
						|-
						| #{iso} || #{year} || [[Plik:#{flag}|22x20px|border]] || <nowiki>{{państwo|#{[iso, variant].compact.join '|'}}}</nowiki> || [[#{title}]]
					EOFF
				}.join("\n").strip
			}
			|}
		EOF
	end
end


if $mode == 'test'
	test_page = Page.new "User:Matma Rex/Wyniki reprezentacji infobox"
	test_page.text = (0..titles.length/50).map{|i| "# [[User:Matma Rex/Wyniki reprezentacji infobox/#{i}]]" }.join("\n")
	test_page.save
end

dane_tpl_cache = {}
iso_cache = {}


titles.each_slice(50).with_index do |titles, i|
	next if i<ARGV[0].to_i
	
	if $mode == 'test'
		test_page = Page.new "User:Matma Rex/Wyniki reprezentacji infobox/#{i}"
		test_page.text = ''
	end
	
	titles.each_with_index do |title, i|
		# puts i, title

		p = Page.new title
		ib = Infobox.parse sss
		
		/\{\| id="?toc"? class="?toccolours"? align="?right"?.*
\| *colspan="5".*?\|(?<impreza>.+|[^|]+)
\|-.*
\| *.+?\[\[(?:file|image|plik|grafika):(?<flaga>[^|]+)\|.+
(?:\|-.*
\|.+?\| *'''Kod (?<organizacja>.+?)''' *
\|.+?\| *(?<panstwo>.+)
)+(?:\|-.*
\|.+?\| *'''(?:MKO[LlI]?|Federacja)''' *
\|.+?\| *.*
)?(?:\|-.*
\|.+?\| *'''(?:Strona www|WWW)''' *
\|.+?\| *.*
)?\|-.*
\|.+?\| *'*(?<impreza2>\[\[.+?\]\])'*\s+[w-–]\s+'*\[\[(?<miejscowosc>[^\|\]]+).* *
(?:\|-.*
\|.+?\| *'''Chorąży''' *
\|.+?\| *(?<chorazy>.*)
)?(?:\|-.*
\|.+?\| *'''Zawodnicy''' *
\|.+?\| *(?<zawodnicy>.*)
(?:\r?\n)?)?(?:\|-.*
\|.+?\| *'''Chorąży''' *
\|.+?\| *(?<chorazy2>.*)
)?(?:\|-.+
\| *colspan=4 *\| *
)?\|-.*
\|.+?\| *'''(?:Meθ?dale|\[\[.+? *\| *Meθ?dale\]\]):? *''' *:?(?:<br ?\/?>)? *:? *(?:<br ?\/?> *(?:Liczba: *|(?:Pozycja[;:]? *)?(?:\[\[Klasyfikacja [^|]+?\d+ *\| *)?(?:Pozycja[;:]? *)?'*(?:\]\] *)?(?<pozycja>\d*|-|–|\?|--)'*\.?'*(?:\]\])?)[ \t]*)?
\|bgcolor="Gold" align=center width="65px" \| '''Złoto'''<br[^>]*>(?:<span[^>]*>)?(?:<\/span>)?(?:<big[^>]*>)? *(?:''')?(?<zlot>\d*|-|–).*?
\|bgcolor="Silver" align=center width="65px" \| '''Srebro'''<br[^>]*>(?:<span[^>]*>)?(?:<\/span>)?(?:<big[^>]*>)? *(?:''')?(?<sreb>\d*|-|–).*?
\|bgcolor="CC9966" align=center width="65px" \| '''Brąz'''<br[^>]*>(?:<span[^>]*>)?(?:<\/span>)?(?:<big[^>]*>)? *(?:''')?(?<braz>\d*|-|–).*?
\|bgcolor="ffffff" align=center width="65px" \| '''Razem'''<br[^>]*>(?:<span[^>]*>)?(?:<\/span>)?(?:<big[^>]*>)? *(?:''')?(?<suma>\d*|-|–).*?
(\|- *
)?(?<koncowka>[\s\S]*?)\|\}(?:\r?\n)*/i =~ p.text # set local vars
		
		old = $& # text to be replaced later
		
		panstwo = cleaned(panstwo).strip.upcase
		impreza = cleaned(impreza).strip
		
		iso_key = if title =~ /^Reprezentacja /
			impreza.split(' na ')[0]
		else
			title.split(' na ')[0]
		end
		
		iso = nil
		if iso_cache[iso_key]
			iso = iso_cache[iso_key]
		else
			iso = "{{Państwo dane #{iso_key}|parametr=skrót}}"
			iso = s.API("action=expandtemplates&text=#{CGI.escape iso}")['expandtemplates']['*'] rescue ''
			iso = nil unless iso=~/^...$/
			
			iso_cache[iso_key] = iso
		end
		
		if !iso or !miejscowosc
			$stderr.puts title unless p.text =~ /\{\{Wyniki reprezentacji infobox/
			next
		end
		
		ib['nazwa'] = title #impreza
		
		organizacja = cleaned(organizacja).strip
		
		# MKOl i MKParaolimpijski + po angielsku
		if organizacja=~/^(MKO[lLI]?|MKP|IOC|IPC)$/ 
			ib['kod MKOl'] = panstwo
			ib['organizacja'] = ib['kod organizacja'] = nil
		else
			ib['organizacja'] = organizacja
			ib['kod organizacja'] = panstwo
			ib['kod MKOl'] = nil
		end
		ib['państwo'] = iso
		
		ib['impreza z linkiem'] = cleaned(impreza2).strip
		ib['miejscowość'] = "[[#{miejscowosc.strip}]]"
		
		ib['chorąży'] = cleaned(chorazy || chorazy2, %w[br ref]).strip
		ib['chorąży'] = '' if ib['chorąży'] == '?'
		
		ib['pozycja w klasyfikacji'] = (pozycja||'').gsub(/\D/, '').strip
		ib['pozycja w klasyfikacji'] = nil if ib['pozycja w klasyfikacji']=='0'
		
		ib['złote'], ib['srebrne'], ib['brązowe'], ib['suma'] = *[zlot, sreb, braz, suma].map(&:strip).map{|a| a.sub /^(-|–)$/, '0'}
		
		
		# shorttagi można olać
		zawodnicy.sub!(/<ref name=[a-z]+\/>/, '') if zawodnicy
		
		if (zawodnicy||'') =~ /<ref/
			puts "!ref! #{title}"
			next
		end
		
		
		/^(\d+)(?: *[,w] *(\d+) konkurenc\w+)?(?: *[,w] *(\d+) dyscypl[io]n\w+)?\s*($|w tym.*|sami.*)/i =~ cleaned(zawodnicy, []).gsub(/[()]/,'').strip
		ib['liczba zawodników'], ib['liczba konkurencji'], ib['liczba dyscyplin'] = $1, $2, $3
		
		if !$&
			/^(\d+)(?: *[,w] *(\d+) dyscypl[io]n\w+)?(?: *[,w] *(\d+) konkurenc\w+)?\s*($|w tym.*|sami.*)/i =~ cleaned(zawodnicy, []).gsub(/[()]/,'').strip
			ib['liczba zawodników'], ib['liczba konkurencji'], ib['liczba dyscyplin'] = $1, $3, $2
		end
		
		
		
		specjale = {
			"Flag of Belgium.svg" => nil,
			"Flag of the USA.svg" => nil,
			"Flag of Angola.svg" => nil,
			"Flag of Germany.svg" => nil,
			"Flag of FR Yugoslavia.svg" => nil,
			"Flag of Switzerland (Pantone).svg" => nil,
			"Flag of Tanzania.svg" => nil,
			# "US flag 44 stars.svg" => '44',
			# "US flag 45 stars.svg" => '45',
			"Flag of Afghanistan 1980.svg" => '1980',
			"Flag of Afghanistan 1987.png" => '1987',
			"Flag of Bulgaria (1946-1967).svg" => '1948',
			"Flag of Fiji (1924).PNG" => '1924',
			"Flag of British East Africa.png" => '1921',
			"Flag of British East Africa.png" => '1921',
			"Flag of British Colonial Nigeria.svg" => '1901',
			"Flag of Puerto Rico (1952-1995).svg" => '1952',
			"South African Olympic Flag.png" => 'ioc-1992',
			"Pre-1999 Flag of Tunisia.svg" => '1959',
			"Ugandaoflag.gif" => '1914',
			"" => '',
		}
		
		dane_tpl = nil
		if dane_tpl_cache[iso]
			dane_tpl = dane_tpl_cache[iso]
		else
			dane_tpl = Page.new("Szablon:Państwo dane #{iso}").text
			if dane_tpl[0] == '#' # redir
				dane_tpl = Page.new( dane_tpl[/\[\[([^\]\|]+)/, 1] ).text
			end
			
			dane_tpl_cache[iso] = dane_tpl
		end
		
		flaga = flaga.gsub(/[ _]+/, ' ').gsub('%28', '(').gsub('%29', ')').gsub("\u200E", '').strip
		rok = title[/\d{4}/].to_i
		
		
		if iso == 'GRC' and rok < 1978
			ib['wariant flagi'] = '1822'
		elsif iso == 'PER' and rok > 1950
			# pass
		elsif iso == 'VEN' and rok <= 2005
			ib['wariant flagi'] = '1930'
		elsif iso == 'YUG' and rok == 1996
			ib['państwo'] = iso = 'SCG'
			ib['wariant flagi'] = 'Jugosławia'
		elsif iso == 'SCG' and rok == 2000 || rok == 2002
			ib['wariant flagi'] = 'Jugosławia'
		elsif iso == 'VNM'
			if rok < 1996
				ib['wariant flagi'] = '1955'
			else
				# pass
			end
		elsif iso == 'USA' and flaga =~ /^US flag (\d+) stars\.(?:svg|png)$/
			ib['wariant flagi'] = $1
			
		elsif specjale.key? flaga
			ib['wariant flagi'] = specjale[flaga].strip if specjale[flaga]
		else
			line = nil
			line = dane_tpl.split(/\r?\n/).select{|a| a.include? flaga}.first
			
			if !line
				# check for redirects
				# puts "redirect check: #{flaga}"
				u = "http://commons.wikimedia.org/w/index.php?title=File:#{CGI.escape flaga}&action=raw"
				ss = (RestClient.get(u).force_encoding('utf-8') rescue '')
				
				if ss[0] == '#' # redir
					flaga = ss[/\[\[:?(?:file|image):([^\]\|]+)/i, 1]
					flaga = flaga.gsub(/[ _]+/, ' ').gsub('%28', '(').gsub('%29', ')').gsub("\u200E", '').strip
					# puts "redirect got: #{flaga}"
					
					line = dane_tpl.split(/\r?\n/).select{|a| a.include? flaga}.first
				end
			end
			
			if line
				if line =~ /[ |]flaga alias[ =]/
					# bez wariantu
				else
					wariant = line[/\| *flaga alias-(.+?) *=/, 1]
					if wariant
						ib['wariant flagi'] = wariant.strip
					else
						$stderr.puts title
						next
					end
				end
			else
				$stderr.puts title
				next
			end
		end
		
		
		
		ib.delete 'wariant flagi' if ib['wariant flagi'].to_s.strip == ''
		
		new = ib.pretty_format()
		
		case $mode
		when 'test'
			test_page.text += (
				"== [[#{title}]] ==\n" +
				["{|", "|style='vertical-align:top'|", old, "|style='vertical-align:top'|", new, "|}"].join("\n") + "\n"
			)
		when 'stats'
			# artykuł, państwo, rok, flaga stara (plik), flaga nowa (wywołanie {{państwo}})
			stats << [title, iso, title[/\d{4}/], flaga, ib['wariant flagi']]
		when 'commit'
			p.replace old, new.strip + "\n"
			# p.save
			p.dump
		end
	end

	begin
		test_page.save if $mode == 'test'
		puts i
	rescue
		puts "#{i} - err?"
	end
end

if $mode == 'stats'
	File.write 'stats.txt', <<-EOF.gsub(/^\t+/, '').strip
		{| class="wikitable sortable"
		! Państwo !! Rok !! Flaga stara !! Flaga nowa !! Artykuł
		#{
			stats.sort_by{|title, iso, year, flag, variant| [iso, year, title] }.map{|title, iso, year, flag, variant|
				<<-EOFF.gsub(/^\t+/, '').strip
					|-
					| #{iso} || #{year} || [[Plik:#{flag}|22x20px|border]] || <nowiki>{{państwo|#{[iso, variant].compact.join '|'}}}</nowiki> || [[#{title}]]
				EOFF
			}.join("\n").strip
		}
		|}
	EOF
end
