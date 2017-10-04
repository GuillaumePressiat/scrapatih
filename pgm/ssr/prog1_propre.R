
an = 15

library(pdftools)
library(pmeasyr)
library(dplyr, warn.conflicts = FALSE)

download.file('http://solidarites-sante.gouv.fr/fichiers/bos/20' %+% an %+% '/sts_20' %+% an %+% '0001_0002_p000.pdf', 
              destfile = 'pdf/ssr/vol_2_20' %+% an %+% '.pdf',
              mode = "wb")



# pdf_info('vol_2_20' %+% an %+% '.pdf')
text <- pdf_text('pdf/ssr/vol_2_20' %+% an %+% '.pdf')
text <- paste(text, collapse = " ")

dir.create('tmp', showWarnings = F)

write.table(text, 'tmp/man_gme_' %+% an %+% '.txt', quote = F, row.names = F, col.names = F)
scan('tmp/man_gme_' %+% an %+% '.txt', what = character()) -> text_2

# Extraction des noms de listes, et correspondance avec les racines de ghm

stringr::str_extract(text_2, 'D-[0-9]{4}') -> diags
stringr::str_extract(text_2, 'A-[0-9]{4}') -> actes
stringr::str_extract(text_2, '[0-9]{4}') -> gn
stringr::str_extract(text_2, 'relatives') -> buttoir



tibble(diags, gn, actes, buttoir) -> test


test %>% 
  filter( is.na(gn) + is.na(actes) + is.na(diags) + is.na(buttoir) < 4) -> test

library(tidyr)
test$gn[test$gn == ""] <- NA
test <- fill(test, gn)


test %>% 
  filter(!is.na(actes) | !is.na(diags)) %>%
  mutate(cmd = substr(gn,1,2)) -> resu

resu %>% 
  select(gn, 
         actes, 
         diags) %>% tidyr::gather('var', 'col', 
                                  actes, 
                                  diags) %>%
  filter(col != '') %>% 
  distinct() -> resu_2

# Libellés

stringr::str_extract_all(text, 'D-[0-9]{4}\\s:.*') %>% purrr::flatten_chr() %>% .[. != ""] %>% 
  unique(.) %>% sort(.) %>% tibble(no = .) %>%
  mutate(col = stringr::str_split(no, ' : ', simplify = T)[,1]) -> l_diags


stringr::str_extract_all(text, 'A-[0-9]{4}\\s:.*') %>% purrr::flatten_chr() %>% .[. != ""] %>%
  unique(.) %>% sort(.) %>% tibble(no = .) %>%
   mutate(col = stringr::str_split(no, ' : ', simplify = T)[,1]) -> l_actes

# 2015
stringr::str_extract_all(text, 'A-[0-9]{4}\\s:.*') %>% purrr::flatten_chr() %>% .[. != ""] %>%
  unique(.) %>% sort(.) %>% tibble(no = .) %>%
  mutate(col = stringr::str_split(no, ' : ' ) %>% purrr::flatten_chr()) -> l_actes

left_join(resu_2, l_diags, by = 'col') -> resu_2
left_join(resu_2, l_actes, by = 'col') -> resu_2


resu_2 <- resu_2 %>% mutate(libelle = ifelse(is.na(no.x), no.y, no.x)) %>% select(-no.x, -no.y)
resu_lib <- resu_2 %>% filter(!is.na(libelle))
distinct(resu_lib, gn, var, code, .keep_all = T) -> resu_lib

rm(resu_2, diags, actes, buttoir, l_actes, l_diags, resu, test)

stringr::str_extract_all(text, "CATEGORIE MAJEURE .*") %>% purrr::flatten_chr() -> cm

# >= 2016
stringr::str_extract_all(text, "CATEGORIE MAJEURE") %>% purrr::flatten_chr()-> cmd
stringr::str_split(text, "CATEGORIE MAJEURE") %>% purrr::flatten_chr() %>% .[-1] -> text_cmd

# 2015
# stringr::str_split(text, "Catégorie majeure") %>% purrr::flatten_chr() %>% .[-1] -> text_cmd
# stringr::str_extract_all(text, "Catégorie majeure") %>% purrr::flatten_chr()-> cmd

i=1
par_cm <- function(i, cmd, text_cmd){
  cat('Catégorie maj '%+% stringr::str_pad(i, 2, "left", "0"), sep = "\n")
  stringr::str_split(text_cmd[[i]], "relatives aux groupes")  -> text_cmd_l
  
  write.table(text_cmd_l[[1]][2], 'tmp/man_gme_cm_tmp.txt', quote = F, row.names = F, col.names = F)
  scan('tmp/man_gme_cm_tmp.txt', what = character()) -> text_2
  
  stringr::str_extract(text_2, 'A{3}\\+[0-9]{3}\\b') -> les_actes
  stringr::str_extract(text_2, '^A-[0-9]{3,4}\\b') -> actes
  stringr::str_extract(text_2, 'RELATIVES') -> buttoir
  stringr::str_extract(text_2, '^D-[0-9]{3,4}\\b') -> diags
  
  stringr::str_extract(text_2, '^[A-Z][0-9]{2}[0-9\\.+]*\\b')-> les_diags
  tibble(text_2, diags, actes, les_diags, les_actes, buttoir) -> test
  
  test <- fill(test, diags, actes, buttoir)
  
  test %>% 
    filter(! (is.na(diags) & is.na(actes)), ! (is.na(les_diags) & is.na(les_actes))) -> resu
  
  resu %>% mutate(id_act = stringr::str_detect(les_actes, "A{3}\\+[0-9]{3}")) %>%
    mutate(id_act = ifelse(is.na(id_act), F, T)) -> resu
  
  resu %>% mutate(code = les_diags,
                  liste = diags) %>% 
    filter(!is.na(liste)) %>% 
    select(liste, code) -> resu_3
  
  if (!is.na(text_cmd_l[[1]][3])){
  write.table(text_cmd_l[[1]][3], 'tmp/man_gme_cm_tmp.txt', quote = F, row.names = F, col.names = F)
  scan('tmp/man_gme_cm_tmp.txt', what = character()) -> text_2
  
  stringr::str_extract(text_2, '[A-Z]{3}\\+[0-9]{3}\\b') -> les_actes
  stringr::str_extract(text_2, '^A-[0-9]{4}\\b') -> actes
  stringr::str_extract(text_2, 'RELATIVES') -> buttoir
  stringr::str_extract(text_2, '^D-[0-9]{3,4}\\b') -> diags
  
  stringr::str_extract(text_2, '^[A-Z][0-9]{2}[0-9\\.+]*\\b')-> les_diags
  tibble(text_2, diags, actes, les_diags, les_actes, buttoir) -> test
  
  test <- fill(test, diags, actes, buttoir)
  
  test %>% 
    filter(! (is.na(diags) & is.na(actes)), ! (is.na(les_diags) & is.na(les_actes))) -> resu
  
  resu %>% mutate(id_act = stringr::str_detect(les_actes, "[A-Z]{3}\\+[0-9]{3}")) %>%
    mutate(id_act = ifelse(is.na(id_act), F, T)) -> resu
  
  resu %>% mutate(code = ifelse(id_act, les_actes, les_diags),
                  liste = ifelse(id_act, actes, diags)) %>% 
    filter(!is.na(liste)) %>% 
    select(liste, code) -> resu_4
  
  resu_3 <- bind_rows(resu_3, resu_4)
  
  }
  
  inner_join(resu_3, resu_lib, by = c('liste' = 'col')) %>% 
    distinct() -> fin

  file.remove('tmp/man_gme_cm_tmp.txt')
  
  fin
}

#par_cm(2, cmd, text_cmd) %>% View()

lapply(1:length(cmd), function(x) par_cm(x, cmd, text_cmd)) -> tout

bind_rows(tout) -> fin

# readr::write_tsv(fin, 'results/ssr/listes_manuel_20' %+% an %+% '_gme_vol_2.txt')

write.csv2(fin, 'results/ssr/listes_manuel_20' %+% an %+% '_gme_vol_2.csv', row.names = F)


# count(distinct(fin, code, liste), liste, sort = T) %>% View

# file.remove('tmp/man_gme_' %+% an %+% '.txt')
