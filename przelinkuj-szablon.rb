# coding: utf-8

require 'sunflower'
s = Sunflower.new.login

tpl = [
	'Mistrzowie Letnich Uniwersjad w rzucie oszczepem',
	'Wicemistrzowie Letnich Uniwersjad w rzucie oszczepem',
	'Brązowi medaliści letnich uniwersjad w rzucie oszczepem',
	'Medaliści uniwersjad w rzucie oszczepem mężczyzn'
]
s.summary = 'popr. szablonu nawigacynego'


list = tpl.map{|tpl| s.make_list 'whatembeds', 'Szablon:'+tpl}.flatten.uniq
list.each do |a|
	p = Page.new a
	tpl.each{|tpl| p.replace(/\{\{#{tpl}\}\}/i, '{{Medaliści uniwersjad w rzucie oszczepem mężczyzn}}') }
	while p.text.scan('{{Medaliści uniwersjad w rzucie oszczepem mężczyzn}}').length > 1
		p.text.sub!("\n"+'{{Medaliści uniwersjad w rzucie oszczepem mężczyzn}}', '')
	end
	p.save
	puts a
	# gets
end
