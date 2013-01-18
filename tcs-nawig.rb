# coding: utf-8

require 'sunflower'
s = Sunflower.new.login
s.summary = "nawigacyjny: {{[[Szablon:Turniej Czterech Skoczni|Turniej Czterech Skoczni]]}}"

l = s.make_list('linkson', 'Szablon:Turniej Czterech Skoczni').grep(/^\d+\./)

re = /\A\s*#{
	Regexp.escape '{|width="100%" cellpadding="5" style="border:solid 2px black;background:#eeeeee;margin-bottom:1em"'
}[\s\S]+?\|\}\s*/

l.each do |t|
	p = Page.new t
	
	if p.text =~ /{{Mistrzostwa indywidualne infobox/
		# pass
	elsif p.text =~ re
		p.text.sub! re, ''
	else
		puts t
		next
	end
	
	if p.text.include? '{{Zwycięzcy Turnieju Czterech Skoczni}}'
		p.text.sub! '{{Zwycięzcy Turnieju Czterech Skoczni}}', '{{Turniej Czterech Skoczni}}'
	else
		puts t
		next
	end
	
	p.save
end




