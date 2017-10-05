library(pdftools)
library(pmeasyr)
library(dplyr, warn.conflicts = FALSE)

an = 11

file_name <- function(an){
  case_when(
         an == 16 ~ "http://www.atih.sante.fr/sites/default/files/public/content/2757/annexe_ipa_v2016_sept2016.pdf",
         an == 15 ~ "http://www.atih.sante.fr/sites/default/files/public/content/2757/annexe_ipa_v11g_juin2015.pdf",
         an == 14 ~ "http://www.atih.sante.fr/sites/default/files/public/content/2757/annexe_ipa_v11f_juillet2014.pdf",
         an == 13 ~ "http://www.atih.sante.fr/sites/default/files/public/content/2757/annexe_ipa_v11e_sept2013.pdf",
         an == 12 ~ "http://www.atih.sante.fr/sites/default/files/public/content/2757/annexe_ipa_v11d_juillet2012.pdf",
         an == 11 ~ "http://www.atih.sante.fr/sites/default/files/public/content/2757/annexe_ipa_v11c_octobre2011.pdf"
         )
}


download.file(file_name(an), 
              destfile = 'pdf/mco/ipa_' %+% an %+% '.pdf',
              mode = "wb")

pdftools::pdf_text(
  'pdf/mco/ipa_' %+% an %+% '.pdf'
  ) -> text

text <- paste(text, collapse = " ")
# write.table(text, 'tmp/ipa' %+% an %+% '.txt', quote = F, row.names = F, col.names = F)

stringr::str_split(text, 'Annexe\\s[0-9]\\s- ', simplify = T)[1,] %>% .[-1] -> text_2
stringr::str_extract_all(text, 'Annexe\\s[0-9]\\s- .*', simplify = T)[1,] -> annexes


annexe <- function(i){
stringr::str_extract_all(text, 'Annexe\\s[0-9]\\s- .*', simplify = T)[1,i] -> titre

text_2[i] %>% 
  stringr::str_extract_all('[A-Z]{4}[0-9]{3}') %>% purrr::flatten_chr() %>% unique()-> liste


tibble(liste, titre)
}

bind_rows(lapply(1:length(annexes), annexe)) -> liste_annexes

write.csv2(liste_annexes, 'results/mco/annexes_ipa_20' %+% an %+% '.csv', row.names = F)

file.remove('tmp/ipa' %+% an %+% '.txt')
