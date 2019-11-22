#!/usr/bin/env ruby

require_relative './misc.rb'

class Section
  def maketex(start_page)
    @start_page = start_page
    emptypage = "\\mbox{}\\newpage"

    chairman_texs = @heads.map do |h|
      <<~HEAD_TEMPLATE
      \\vspace{5mm}
      \\includegraphics[height=5cm]{../../portraits/#{h.photo}}\\\\
      \\vspace{2mm}
      {\\large \\textbf{\\textsf{#{h.name}}}}\\\\
      \\textsf{#{h.title}}

      HEAD_TEMPLATE
    end

    titletex = <<~TT_OERLAY_TEMPLATE
      \\begin{center}
      \\pdfbookmark[1]{#{@name}}{abspage-#{start_page}}

      {\\Large \\textbf{\\textsf{#{@name}}}}

      #{chairman_texs.join "\n\n\\vspace{5mm}"}
      \\end{center}
      \\newpage
      TT_OERLAY_TEMPLATE

    warning = if @status == true then '' else "{\\Huge \\color{red}~#{@status}}\n" end

    cur_page = start_page + 2

    articles_tex = @articles.map do |a|
      a.start_page = cur_page
      ocp = cur_page
      cur_page += 1
      "\\renewcommand{\\headrulewidth}{0pt}\\newgeometry{margin=15mm,top=21mm}\\resetHeadWidth" +
      if ocp.odd? then
        %(\\thispagestyle{fancy}\\fancyhf{}\\lhead{}\\rhead{#{ocp}})
      else
        %(\\thispagestyle{fancy}\\fancyhf{}\\lhead{#{ocp}}\\rhead{})
      end +
      "\\pdfbookmark[2]{#{a.title}}{abspage-#{ocp}}\n" +
      "\\mbox{}\\newpage\\renewcommand{\\headrulewidth}{0.4pt}\\restoregeometry\\resetHeadWidth\n" +
      (2..a.pagescount).map do |p|
        ocp = cur_page
        cur_page += 1
        if ocp.odd? then
          %(\\thispagestyle{fancy}\\fancyhf{}\\lhead{\\truncate{4.25in}{\\footnotesize #{a.title}}}\\rhead{~~#{ocp}})
        else
          %(\\thispagestyle{fancy}\\fancyhf{}\\lhead{#{ocp}~~}\\rhead{\\truncate{4.25in}{\\footnotesize #{@confname}}})
        end + '\mbox{}\newpage'
      end.join("\n")
    end.join("\n\n")

    add_empty = cur_page.even?

    finalemptypage = if add_empty then # last is odd
      cur_page += 1
      emptypage
    else
      ''
    end

    section_templ = ERB::new(File::read(File::join(File::dirname(__FILE__), 'section_tex.erb')))
    section_tex = section_templ.result binding

    File::open(File::join(@folder, "_section-overlay.tex"), "w:UTF-8") do |f|
      f.write section_tex 
    end

    File::open(File::join(@folder, "_section-compile.sh"), "w:UTF-8") do |f|
      pdfs = ['../../generator/a5-empty.pdf'] * 2 +
        @articles.map { |a| File::basename(a.fullfile) } +
        if add_empty then ['../../generator/a5-empty.pdf'] else [] end

      f.write <<~COMPILE
        #!/bin/bash
        xelatex _section-overlay.tex
        xelatex _section-overlay.tex

        pdftk #{pdfs.join ' '} cat output _section-articles.pdf
        pdftk _section-overlay.pdf multibackground _section-articles.pdf output #{@pdfname}

        mv #{@pdfname} ..

        COMPILE
    end

    File::u_plus_x File::join(@folder, "_section-compile.sh")

    cur_page
  end
end
      
      