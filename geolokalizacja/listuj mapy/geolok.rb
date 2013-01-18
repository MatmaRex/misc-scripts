# coding: utf-8
# Author: http://pl.wikipedia.org/wiki/Wikipedysta:Matma_Rex

require 'sunflower'
require 'io/console'
$stdout.sync = true

# work around a timeout in pages_preloaded
class Sunflower; def is_bot?; false; end end

print 'Password: '
s = Sunflower.new('pl.wikipedia.org').login 'MatmaBot', STDIN.noecho(&:gets).strip
puts ''

total_count = 0
total_count_redirs = 0
# returns: { subcats:[ [cat, { (recursive) } ], items:[...] }
# set total_count
process = lambda{|category|
	list = s.make_list 'category', category
	subcats, items = * list.partition{|a| a.start_with? "#{s.ns_local_for 'category'}:" }
	subcats.reject!{|a| a =~ /błędy/ }
	
	redir_pages, item_pages = * s.make_list('pages', items).pages_preloaded.partition{|p| p.text[0] == ?# }
	items = item_pages.map(&:title).reject{|a| a == 'Szablon:Mapa dane żadna' }
	redirs = redir_pages.map{|p| [ p.title, p.text[/\[\[([^\|\]]+)/, 1] ] }
	
	total_count += items.length
	total_count_redirs += redirs.length
	{ subcats: subcats.map{|c| [c, process.call(c)] }, items: items, redirs: redirs }
}

def param a; '{{subst:mapa dane $1|subst:#switch:'+a+'}}'; end

def perhead_text heading, lev, items, redirs
	line_fmt = "#{param 'mapa'} {{subst:!}} [[Szablon:Mapa dane $1|$1]] (→ [[#{param 'link alias'}]]) {{subst:#if:#{param 'mapa-hydro'}|+ hydro}} {{subst:#if:#{param 'mapa-fizyczna'}|+ fizyczna}}"
	just_name = lambda{|a| a.gsub('Szablon:Mapa dane ', '') }
	
	title = heading.sub('Kategoria:Szablony lokalizacyjne - ', '').tap{|s| s[0] = s[0].upcase } if heading

	(heading ? "#{'=' * lev} [[:#{heading}|#{title}]] (#{items.length} / #{redirs.length}) #{'=' * lev}\n" : '') +
	(!redirs.empty? ? "<span class=plainlinks>\n" +
	redirs.map{|from, to| "[{{fullurl:#{from}|redirect=no}} #{just_name.call from}] → [[#{to}|#{just_name.call to}]]" }.join(" •\n") +
	"</span>\n\n" : '') +
	(!items.empty? ? "{{subst:#tag:gallery|\n" +
	items.map{|a| line_fmt.gsub '$1', just_name.call(a) }.join("\n") +
	"\n}}\n\n" : '' )
end

# input: as returned from process
# returns: wikitext string
output = lambda{|heading, lev, data|
	out = perhead_text heading, lev, data[:items], data[:redirs]
	data[:subcats].each{|heading, data| out += output.call heading, lev+1, data }
	out
}


full_text = <<EOF
Lista wszystkich zdefiniowanych map lokalizacyjnych. Map: %d, przekierowań: %d. Ostatnia aktualizacja: ~~~~~.

%s

[[Kategoria:Wikiprojekt Geolokalizacja]]
EOF

# while true
	begin
		total_count = 0
		total_count_redirs = 0
		data = process.call 'Kategoria:Szablony lokalizacyjne'
		out = output.call nil, 1, data
		
		p = Sunflower::Page.new 'Wikiprojekt:Geolokalizacja/Galeria mapek lokalizacyjnych'
		p.text = full_text % [total_count, total_count_redirs, out]
		p.save p.title, 'aktualizacja listy'
		# p.dump
		
		puts "Done. #{Time.now}."
		sleep 24*60*60
	rescue Exception
		puts $!, $!.backtrace
	end
# end
