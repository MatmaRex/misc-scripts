# coding: utf-8
require 'sunflower'
require 'pp'
require './infobox parser.rb'

s = Sunflower.new.login

titles = (s.make_list 'whatembeds', 'Szablon:Postać Śródziemie infobox').sort
titles = titles.reject{|a| a.include? ':'}

$mode = (ARGV[0] == '--commit' ? :commit : :test)

if $mode == :test
	s.summary = 'test infoboksu'
	
	test_page = Page.new 'User:Matma Rex/władca pierścieni - test'
	test_page.text = ''
else
	s.summary = 'poprawki {{[[szablon:Postać Śródziemie infobox|Postać Śródziemie infobox]]}}'
end

titles.each_with_index do |title, i|
	puts "#{i.to_s.rjust 3} #{title}"[0...80]

	p = Page.new title
	p.text = p.text.gsub(/{{Szablon\s*:\s*/i, '{{')
	
	orig_text = Infobox.extract_ib_from_text p.text, 'Postać Śródziemie'
	ib = Infobox.parse orig_text
	
	# regeneration!
	renames = {
		'inne_imiona' => 'inne imiona',
		'imiona' => 'inne imiona',
		'Znany jako' => 'inne imiona',
		'tłumaczenie_braiter' => 'tłumaczenie Braiter',
		'tłumaczenie_frąc' => 'tłumaczenie Frąc',
		'tłumaczenie_frącowie' => 'tłumaczenie Frąc',
		'tłumaczenie_kot' => 'tłumaczenie Kot',
		'tłumaczenie_łoziński' => 'tłumaczenie Łoziński',
		'tłumaczenie_skibniewska' => 'tłumaczenie Skibniewska',
		'adaptacja' => 'aktor Władca Pierścieni',
		'wystąpienia' => 'literatura przedmiotu',
		'imię org' => 'imię oryg',
	}
	
	params = (Infobox.parse '{{Whatevs infobox|imię=|imię oryg=|grafika=|opis=|lata życia=|rasa i kultura=|kraina=|inne imiona=|tytuły=|ojciec=|matka=|rodzeństwo=|towarzysz=|potomstwo=|tłumaczenie Braiter=|tłumaczenie Frąc=|tłumaczenie Kot=|tłumaczenie Łoziński=|tłumaczenie Skibniewska=|literatura przedmiotu=|aktor Władca Pierścieni=|aktor Hobbit=}}').keys
	
	param_order = reqd_params = params
	
	# rename parameters
	renames.each do |from, to|
		if ib[from]
			ib[to] = ib[from]
			ib.delete from
		end
	end
	
	
	# joins
	# lata życia
	ur = (ib['data_urodzenia']||'').strip
	zm = (ib['data_śmierci']||'').strip
	ib['lata życia'] ||= "#{ur!='' ? ur : '?'} – #{zm!='' ? zm : '?'}"
	
	# rasa i kultura
	ib['rasa'] = ib['rasa'].sub(/^(\[\[[^\|]+\||\[\[|)([A-Z])/){$1 + $2.downcase} if ib['rasa'] # rasa małą literą - nie można [0], bo linki itp.
	ib['rasa i kultura'] ||= [ib['rasa'], ib['kultura']].select{|a| a && a.strip!=''}.join ', '
	
	# remove unused fields
	ib.each_key do |k|
		if !(params.include? k.to_s)
			ib.delete k
			puts "unrecognized parameter: #{k} on #{title}" unless (%w[abstrakt płeć oręż data_urodzenia data_śmierci rasa kultura tłumaczenie_frącowie imiona] + ['Znany jako']).include? k
		end
	end
	
	
	# magic
	unless ib['imię'] and ib['imię']!=''
		ib['imię'] = title
	end
	
	new_text = ib.pretty_format param_order: param_order, reqd_params: reqd_params
	
	
	if $mode == :test
		new_text = new_text.sub('Postać Śródziemie infobox', 'Wikipedysta:Tar Lócesilion/brudnopis/2')
		
		test_page.text += (
			"== [[#{title}]] ==\n" +
			["{|", "|style='vertical-align:top'|", orig_text, "|style='vertical-align:top'|", new_text, "|}"].join("\n") + "\n"
		)
	else
		p.text = p.text.sub(/#{Regexp.escape orig_text}(\r?\n)*/, new_text + "\n")
		p.save
	end
end

if $mode == :test
	test_page.text += "\n\n<references />" if test_page.text=~/<ref/
	test_page.save
end
