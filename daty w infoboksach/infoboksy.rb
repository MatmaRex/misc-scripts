# coding: utf-8

require 'sunflower'
require 'pp'

class Page; attr_accessor :orig_text; end

s = Sunflower.new.login
list = File.readlines('lista.txt', external_encoding:'utf-8').map(&:strip)

pairs = [
	{infobox: 'Aktor erotyczny',          para: 'aktywność'         },
	{infobox: 'Aktor',                    para: 'Lata aktywności'   },
	{infobox: 'Artysta muzyczny',         para: 'aktywność'         },
	{infobox: 'Audycja radiowa',          para: 'lata emisji'       },
	{infobox: 'Auto',                     para: 'okres produkcji'   },
	{infobox: 'Autobus',                  para: 'Okres produkcji'   },
	{infobox: 'Bomba',                    para: 'czasuzycia'        },
	{infobox: 'Bomba',                    para: 'produkcja'         },
	{infobox: 'Broń palna',               para: 'produkcja_seryjna' },
	{infobox: 'Czołg',                    para: 'data prototypu'    },
	{infobox: 'Czołg',                    para: 'lata produkcji'    },
	{infobox: 'Duchowny',                 para: '1. funkcja - okres'},
	{infobox: 'Duchowny',                 para: '2. funkcja - okres'},
	{infobox: 'Działo holowane',          para: 'produkcja_seryjna' },
	{infobox: 'Festiwal muzyczny',        para: 'aktywność'         },
	{infobox: 'Filmowiec',                para: 'Aktywność'         },
	{infobox: 'Filmowiec',                para: 'Lata aktywności'   },
	{infobox: 'Gitara',                   para: 'Lata Produkcji'    },
	{infobox: 'Hymn',                     para: 'lata obowiązywania'},
	{infobox: 'Koszykarz',                para: 'aktywność'         },
	{infobox: 'Lokomotywa elektryczna',   para: 'lata_budowy'       },
	{infobox: 'Lokomotywa spalinowa',     para: 'lata_budowy'       },
	{infobox: 'Lotnicza broń strzelecka', para: 'produkcja_seryjna' },
	{infobox: 'Motocykl',                 para: 'Okres_produkcji'   },
	{infobox: 'Państwo',                  para: 'lata_istnienia'    },
	{infobox: 'Pisarz',                   para: 'okres'             },
	{infobox: 'Pocisk rakietowy',         para: 'czasuzycia'        },
	{infobox: 'Pocisk rakietowy',         para: 'produkcja'         },
	{infobox: 'Program telewizyjny',      para: 'lata emisji'       },
	{infobox: 'Samolot',                  para: 'lata produkcji'    },
	{infobox: 'Serial',                   para: 'lata_emisji'       },
	{infobox: 'Szynobus',                 para: 'lata_budowy'       },
	{infobox: 'UNESCO',                   para: 'zagrożenie'        },
	{infobox: 'Zespół F1',                para: 'Aktywna'           },
	{infobox: 'Zespół trakcyjny',         para: 'lata_budowy'       },
	{infobox: 'Żołnierz',                 para: 'lata służby'       },
]

class Passer
	def initialize *all
		@passto = all
	end
	
	def method_missing *a, &b
		@passto.each{|o| o.send *a, &b}
	end
	def respond_to? m
		@passto.all?{|o| o.respond_to? m}
	end
end

if ARGV[0]=='--from'
	from = ARGV[1].to_i
	ARGV.shift 2
end


log = File.open('log.txt', 'a')
log.sync = true
trap('INT'){log.close; exit}

$stdout = Passer.new log, $stdout

todo_regex = /#{File.read('db scanner regex.txt', external_encoding:'utf-8')}/


def progress_msg done, max, title, msg
	puts "#{done.to_s.rjust max.to_s.length}/#{max} #{title[0..30].ljust 31}| #{msg}"
end


slowly = false
list.each_with_index do |name, i|
	next if from and from>=i
	
	summaryparts = []
	ibs_fixed = []
	
	p = Page.get name
	old_p_text = p.text.dup
	p.orig_text = old_p_text
	
	pairs.each do |hsh|
		if p.text =~ /\{\{#{hsh[:infobox]} infobox/i
			did_change = p.text.gsub!(/(#{hsh[:para]} *= *)(?:\[\[)?(\d{4})(?:\]\]| [^\]]+\]\])? *[-—–] *(?:obecnie|nadal|teraz|do teraz|dzisiaj|do dzisiaj|dziś|do dziś|aktualnie|teraźniejszość|present|)(\s*[\|\}])/) do
				before, year, after = $1, $2, $3
				"#{before}od #{year}#{after}"
			end
			
			ibs_fixed << hsh[:infobox] if did_change
		end
	end
	
	if p.text =~ /\{\{(władca|Poprzednik Następca)/i
		did_change = p.text.gsub!(/(lata *= *)(?:\[\[)?(\d{4})(?:\]\]| [^\]]+\]\])? *[-—–] *(?:obecnie|nadal|teraz|do teraz|dzisiaj|do dzisiaj|dziś|do dziś|aktualnie|teraźniejszość|present|)(\s*[\|\}])/) do
			before, year, after = $1, $2, $3
			"#{before}od #{year}#{after}"
		end
		
		wladca_fixed = true if did_change
	end

	
	if (ibs_fixed.empty? and !wladca_fixed) or p.text == old_p_text
		if p.text =~ todo_regex
			msg = 'todo, has: '+p.text.scan(/\{\{(.+?) (?=infobox)/).uniq.join(', ')
		else
			msg = 'already'
		end
		
		progress_msg i+1, list.length, name, msg
		
		next
	end
	
	summary = (
		'poprawa zapisu przedziałów dat w ' +
		[
			ibs_fixed.uniq.map{|nm| "{{[[szablon:#{nm} infobox|#{nm} infobox]]}}"}.join(', '),
			(wladca_fixed ? 'szablonach sukcesji' : '')
		].select{|a| a!=''}.join(' oraz ')
	)
	
	old_p_text = p.text.dup
	p.code_cleanup
	
	if old_p_text != p.text
		summary += ', [[WP:SK]]'
	end
	
	
	
	s.summary = summary
	p.save
	s.summary = nil
	
	progress_msg i+1, list.length, name, [ibs_fixed.uniq.join(', '), (wladca_fixed ? 'wladca' : '')].select{|a| a!=''}.join(' / ')
	
	if slowly
		slowly = !(gets.strip=='ok')
	end
end
