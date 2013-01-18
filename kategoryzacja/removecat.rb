# coding: utf-8
require 'sunflower'
s = Sunflower.new.login

from = <<EOF
Kategoria:Polscy matematycy żydowskiego pochodzenia
EOF

from = from.strip.split(/\r?\n/).map{|from| from.strip!; from.start_with?('Kategoria:') ? from : 'Kategoria:'+from }

summary = "usunięcie kategorii %s, [[Wikipedia:Poczekalnia/kwestie techniczne/2012:09:25:Kategoria:Polscy matematycy żydowskiego pochodzenia|decyzja z poczekalni]]; [[WP:SK]]"

list = from.map{|from| s.make_list 'category', from }.flatten.sort.uniq
(s.make_list 'pages', list).pages_preloaded.each do |p|
	p.code_cleanup
	which = []
	from.each do |from|
		which<<from.sub(/^Kategoria:/,'') if p.text.gsub!(/\[\[#{Regexp.escape from}(\|[^\]]*)?\]\](\r?\n)?/i, '')
	end
	p p.save p.title, summary%which.join(', ') unless which.empty?
	# gets
end
