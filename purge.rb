# coding: utf-8

require 'sunflower'
s = Sunflower.new.login

l = s.make_list 'whatembeds', 'Szablon:Zabytki wiersz/koordynaty'

l.each_slice(50) do |titles|
	begin
		s.API action: 'purge', forcelinkupdate: true, titles: titles.join('|')
	rescue RestClient::Exception => e
		titles.each do |t|
			s.API action: 'purge', forcelinkupdate: true, titles: t
		end
	else
		puts 'okay'
	end
end
