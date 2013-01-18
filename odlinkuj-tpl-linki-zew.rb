# coding: utf-8
require 'sunflower'
require 'timeout'
require 'io/console'

s = Sunflower.new('pl.wikipedia.org').login('MatmaBot', (STDIN.noecho &:gets).strip)

s.summary = 'usunięcie odwołania do usuniętego szablonu {{Linki zewnętrzne}} ([[Wikipedia:Poczekalnia/kwestie techniczne/2012:01:15:Szablon:Linki zewnętrzne|dysk. w pocz.]], [[Wikipedia:Głosowania/Wielkość czcionki w sekcjach końcowych 2|głosowanie]])'

linki_re = /\{\{[lL]inki zewnętrzne\s*\|\s*(?:column\s*=\s*\d+\s*\|\s*)?(?:1\s*=\s*)?((?:[^{}]+?|{{(?:[^{}]+?|{{[^{}]+}}|\{[P\d]+\})+}}|\{[P\d]+\})+)\|?\}\}/

list = s.make_list 'whatembeds', "szablon:linki zewnętrzne"

list.each_with_index do |title, i|
	puts "#{(list.length - i).to_s.rjust 4} #{title}..."
	begin
	Timeout.timeout(10) do
		p = Page.new title
		p.text = p.text.gsub(linki_re){
			$1.strip.gsub('%7C', '|').gsub('{{=}}', '=').gsub('{{!}}', '|').sub(/\|\Z/, '').strip
		}
		p.text.gsub! /\{\{linki zewnętrzne\|*\}\}/i, ''
		p.save
	end
	rescue 
	end
end

