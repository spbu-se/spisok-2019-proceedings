#!/usr/bin/env ruby

require_relative './metadata.rb'
require_relative './generator.rb'
require_relative './toc.rb'
require_relative './whole.rb'

confname = "{\\addfontfeature{LetterSpace=-3.5}Материалы 8-й всероссийской научной конференции по проблемам информатики СПИСОК-2019}"

sections = load_all_sections(confname)

cpage = 5

sections.each do |s|
  cpage = s.maketex(cpage)
end

gen_toc(sections, "Содержание", confname, cpage)

gen_whole(sections)
