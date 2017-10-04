  
  an = 14
  
  library(pdftools)
  library(pmeasyr)
  library(dplyr, warn.conflicts = FALSE)
  
  
  download.file('http://solidarites-sante.gouv.fr/fichiers/bos/20' %+% an %+% '/sts_20' %+% an %+% '0005_0002_p000.pdf', 
                destfile = 'pdf/mco/vol_2_20' %+% an %+% '.pdf',
                mode = "wb")
  
  
  # pdf_info('vol_2_20' %+% an %+% '.pdf')
  text <- pdf_text('pdf/mco/vol_2_20' %+% an %+% '.pdf')
  text <- paste(text, collapse = " ")
  
  # write.table(text, 'tmp/man_ghm_' %+% an %+% '.txt', quote = F, row.names = F, col.names = F)
  
  stringr::str_extract_all(text, "CATÉGORIE MAJEURE DE DIAGNOSTIC n° [0-9]{2}") %>% purrr::flatten_chr()-> cmd
  stringr::str_split(text, "CATÉGORIE MAJEURE DE DIAGNOSTIC n°") %>% purrr::flatten_chr() %>% .[-1] -> text_cmd
  
  
  dir.create('tmp', showWarnings = F)
  i=1
  par_cmd <- function(i, cmd, text_cmd){
    cat(cmd[i], "\n")
    
    stringr::str_split(text_cmd[[i]], "RELATIVES AUX GROUPES DE LA CMD|LISTE DES GROUPES DE LA CM n° 90")  -> text_cmd_l
    
    write.table(text_cmd_l[[1]][1], 'tmp/man_ghm_cmd_tmp.txt', quote = F, row.names = F, col.names = F)
    scan('tmp/man_ghm_cmd_tmp.txt', what = character(), sep = "\n") -> text_2
    
    # Extraction des noms de listes, et correspondance avec les racines de ghm
    
    stringr::str_extract(text_2, 'D-[0-9]{3,4}') -> diags
    stringr::str_extract(text_2, 'A-[0-9]{3,4}') -> actes
    stringr::str_extract(text_2, 'A-[0-9]{3,4}|D-[0-9]{3,4}') -> listes
    stringr::str_extract(text_2, '[0-9]{2}[A-Z][0-9]{2}[1234ABCDZTEJ]?') -> rghm
    
    tibble(text_2, ident = 1:length(text_2), diags, rghm, actes, listes) -> test
    
    
    test %>% 
      filter( is.na(rghm) +  is.na(listes) < 2 ) -> test
    
    library(tidyr)
    test$rghm_old <- test$rghm
    test$rghm[test$rghm == ""] <- NA
    test <- fill(test, rghm)
    

    test %>%
      arrange(rghm) %>% 
      filter(!grepl('\\*', text_2)) %>% 
      group_by(rghm) %>%
      filter(row_number() > 2) %>%
      filter(nchar(rghm) == 5 | substr(rghm,6,6) %in% c('Z', 'E', 'J')) -> test
  

    test %>%
      mutate(cmd = substr(rghm,1,2)) -> resu
    
    resu %>% select(rghm, actes, diags) %>% tidyr::gather('var', 'col', actes, diags) %>%
      filter(col != '') %>% 
      distinct() -> resu_2
    
    
    
    # Libellés
    
    stringr::str_extract_all(text, 'D-[0-9]{3,4}\\s:.*') %>% purrr::flatten_chr() %>% .[. != ""] %>% unique(.) %>% sort(.) %>% tibble(no = .) %>%
      mutate(col = stringr::str_split(no, ' : ', simplify = T)[,1]) -> l_diags
    
    stringr::str_extract_all(text, 'A-[0-9]{3}\\s:.*') %>% purrr::flatten_chr() %>% .[. != ""] %>% unique(.) %>% sort(.) %>% tibble(no = .) %>%
      mutate(col = stringr::str_split(no, ' : ', simplify = T)[,1]) -> l_actes
    
    left_join(resu_2, l_diags, by = 'col') -> resu_2
    left_join(resu_2, l_actes, by = 'col') -> resu_2
    
    
    resu_2 <- resu_2 %>% mutate(libelle = ifelse(is.na(no.x), no.y, no.x)) %>% select(-no.x, -no.y)
    resu_lib <- resu_2 %>% filter(!is.na(libelle))
    
    rm(resu_2, diags, actes, l_actes, l_diags, resu, rghm, test)
    
    
    
    write.table(text_cmd_l[[1]][2], 'tmp/man_ghm_cmd_tmp.txt', quote = F, row.names = F, col.names = F)
    scan('tmp/man_ghm_cmd_tmp.txt', what = character()) -> text_2
    
    stringr::str_extract(text_2, '[[:upper:]]{4}[[:digit:]]{3}\\b') -> les_actes
    stringr::str_extract(text_2, '^A-[0-9]{3,4}\\b') -> actes
    stringr::str_extract(text_2, 'RELATIVES') -> buttoir
    stringr::str_extract(text_2, '^D-[0-9]{3,4}\\b') -> diags
    
    stringr::str_extract(text_2, '^[A-Z][0-9]{2}[0-9\\.+]*\\b')-> les_diags
    tibble(text_2, diags, actes, les_diags, les_actes, buttoir) -> test
    
    test <- fill(test, diags, actes, buttoir)
    
    test %>% 
      filter(! (is.na(diags) & is.na(actes)), ! (is.na(les_diags) & is.na(les_actes))) -> resu
    
    resu %>% mutate(id_act = stringr::str_detect(les_actes, "[[:upper:]]{4}[[:digit:]]{3}")) %>%
      mutate(id_act = ifelse(is.na(id_act), F, T)) -> resu
    
    resu %>% mutate(code = ifelse(id_act, les_actes, les_diags),
                    liste = ifelse(id_act, actes, diags)) %>% 
      filter(!is.na(liste)) %>% 
      select(liste, code) -> resu_3
    
    if (!is.na(text_cmd_l[[1]][3])){
    write.table(text_cmd_l[[1]][3], 'tmp/man_ghm_cmd_tmp.txt', quote = F, row.names = F, col.names = F)
    scan('tmp/man_ghm_cmd_tmp.txt', what = character()) -> text_2
    
    stringr::str_extract(text_2, '[[:upper:]]{4}[[:digit:]]{3}\\b') -> les_actes
    stringr::str_extract(text_2, '^A-[0-9]{3,4}\\b') -> actes
    stringr::str_extract(text_2, 'RELATIVES') -> buttoir
    stringr::str_extract(text_2, '^D-[0-9]{3,4}\\b') -> diags
    
    stringr::str_extract(text_2, '^[A-Z][0-9]{2}[0-9\\.+]*\\b')-> les_diags
    tibble(text_2, diags, actes, les_diags, les_actes, buttoir) -> test
    
    test <- fill(test, diags, actes, buttoir)
    
    test %>% 
      filter(! (is.na(diags) & is.na(actes)), ! (is.na(les_diags) & is.na(les_actes))) -> resu
    
    resu %>% mutate(id_act = stringr::str_detect(les_actes, "[[:upper:]]{4}[[:digit:]]{3}")) %>%
      mutate(id_act = ifelse(is.na(id_act), F, T)) -> resu
    
    resu %>% mutate(code = ifelse(id_act, les_actes, les_diags),
                    liste = ifelse(id_act, actes, diags)) %>% 
      filter(!is.na(liste)) %>% 
      select(liste, code) -> resu_4
    
    resu_3 <- bind_rows(resu_3, resu_4)
    }
    inner_join(resu_3, resu_lib, by = c('liste' = 'col')) %>% 
      mutate(cmd = cmd[i]) %>%
      distinct() -> fin
  
    file.remove('tmp/man_ghm_cmd_tmp.txt')
    fin
  }
  
  # par_cmd(1, cmd, text_cmd) %>% View()
  
  lapply(1:length(cmd), function(x) par_cmd(x, cmd, text_cmd)) -> tout
  
  bind_rows(tout) -> fin
  
  # readr::write_tsv(fin, 'results/mco/listes_manuel_20' %+% an %+% '_ghm_vol_2.txt')
  
  write.csv2(fin, 'results/mco/listes_manuel_20' %+% an %+% '_ghm_vol_2.csv', row.names = F)
  
  # count(distinct(fin, code, liste), liste, sort = T) %>% View
  
  # file.remove('tmp/man_ghm_' %+% an %+% '.txt')
  
  distinct(fin, rghm, liste) %>% arrange(rghm, liste) %>% select(rghm, liste) %>% View
