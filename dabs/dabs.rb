# coding: utf-8
require 'sunflower'
require 'io/console'

$stdout.sync = $stderr.sync = true
$stderr.puts 'Input password:'
s = Sunflower.new('pl.wikipedia.org').login('MatmaBot', STDIN.noecho(&:gets).strip)

loop do
	d = Time.now.strftime '%Y%m%d'
	url = "http://toolserver.org/~saper/disambiglinks/#{d}.txt"

	all = RestClient.get(url).force_encoding('utf-8')
	all = all.split(/\r?\n/).map{|a| p, n = *a.split(/\t/); [p.gsub('_', ' '), n.to_i] }

	def fmtpages ary
		list = ary.map{|p,n| "* [[#{p}]] ([[Specjalna:Linkujące/#{p}|#{n} {{sub"+"st:plural:#{n}|link|linki|linków}}]])" }
		
		return list.each_slice(20).map.with_index{|lst, i| "== Sekcja #{i+1} ==\n" + lst.join("\n") + "\n\n" }.join('')
	end


	introtext = "Poniżej znajduje się lista [[:Kategoria:Strony ujednoznaczniające|stron ujednoznaczniających]], do których wiodą linki z innych artykułów. Ostatnia aktualizacja: #{'~'*5}.\n__NOTOC__\n\n"


	s.summary = "aktualizacja na bazie: [#{url}]"

	p = Page.new "Wikiprojekt:Strony ujednoznaczniające z linkami/50+"
	p.text = "{{skrót|[[WP:LSU]]}}\n" + introtext + fmtpages(all.select{|p, n| n>=50})
	p.save

	p = Page.new "Wikiprojekt:Strony ujednoznaczniające z linkami/30-49"
	p.text = introtext + fmtpages(all.select{|p, n| n.between? 30, 49})
	p.save

	p = Page.new "Wikiprojekt:Strony ujednoznaczniające z linkami/10-29"
	p.text = introtext + fmtpages(all.select{|p, n| n.between? 10, 29})
	if p.text.length > 200_000
		p.text = p.text[0, 200_000]
		p.text.gsub! /.+\n*\Z/, "\n..."
	end
	p.save

	p = Page.new "Wikiprojekt:Strony ujednoznaczniające z linkami/5-9"
	p.text = introtext + fmtpages(all.select{|p, n| n.between? 5, 9})
	if p.text.length > 200_000
		p.text = p.text[0, 200_000]
		p.text.gsub! /.+\n*\Z/, "\n..."
	end
	p.save
	
	puts "Done. #{Time.now}"
	sleep 24*60*60
end

