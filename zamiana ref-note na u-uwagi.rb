# coding: utf-8
require 'sunflower'

s = Sunflower.new.login
s.summary = "zamiana przypisów na <ref>"

l = s.make_list 'whatembeds', 'szablon:note'
l += s.make_list 'whatembeds', 'szablon:ref'
l.uniq!
l &= s.make_list 'category', 'Kategoria:Członkowie Organizacji Narodów Zjednoczonych'

l = s.make_list 'pages', l


l.pages_preloaded.each do |p|
	uw = []

	if p.text.sub! /{{Note\|1}}\s*(.+?)(<br *\/?>|$)/i do
			uw << "<ref name=infobox1>#{ $1 }</ref>"
			''
		end
		unless p.text.gsub! /\s*{{Ref\|1}}/i, '{{u|infobox1}}'
			uw.pop
		end
	end

	if p.text.sub! /{{Note\|2}}\s*(.+?)(<br *\/?>|$)/i do
			uw << "<ref name=infobox2>#{ $1 }</ref>"
			''
		end
		unless p.text.gsub! /\s*{{Ref\|2}}/i, '{{u|infobox2}}'
			uw.pop
		end
	end
	
	if uw.length>0 and  p.text.sub! /((==+|{{)\s*przypisy)/i, "{{Uwagi|uwagi=\n#{ uw.join "\n" }\n}}\n\\1"
		p.save
	end
	
	puts p.title
end
