library(pdftools)
library(dplyr, warn.conflicts = F)
library(readr)

# regexpr utile
rrracine <- '[0-9]{2}[A-Z][0-9]{2}[1234ABCDZTEJ]?'

# Télécharger le pdf du jo, 2017 ici
# https://www.legifrance.gouv.fr/jo_pdf.do?id=JORFTEXT000034203360
# 2017
# pdf_text('pdf/mco//joe_20170317_0065_0016.pdf') -> u
# 2018
pdf_text('pdf/mco//joe_20180306_0054_0011.pdf') -> u

# Pour observer l'objet, fichier temp
write.table(u, 'tmp/tarifs.txt', quote = F, row.names = F, col.names = F)

# Repérer les pages avec les tarifs a, b, c  
paste(u[4:145], collapse = " ") %>% stringr::str_split(., "\\n") %>% purrr::flatten_chr() %>% tibble(x  = .) %>% 
  mutate(x = stringr::str_replace(x, 'Texte [0-9]{2,} sur [0-9]{2,}', '')) -> v

# Repérer les pages avec les tarifs d  
paste(u[151:290], collapse = " ") %>% stringr::str_split(., "\\n") %>% purrr::flatten_chr() %>% tibble(x  = .) %>% 
  mutate(x = stringr::str_replace(x, 'Texte [0-9]{2,} sur [0-9]{2,}', '')) -> v

# On extrait les libellés longs (les lignes à la ligne, pour reconstituer ensuite le libellé entier)
v %>% 
  filter(stringr::str_trim(substr(x,1,80)) != "",
         !grepl('GHS\\s*GHM|basse', x)) %>% 
  mutate(ghm = stringr::str_detect(x, rrracine),
         ghm_ = stringr::str_extract(x, rrracine),
         lib_long = lag(ghm),
         lib_suite = ifelse(lead(ghm), x, ""), 
         ghm__ = ghm_) %>% 
  tidyr::fill(ghm_) %>% 
  filter(is.na(ghm__) & lib_suite != "" & !is.na(ghm_)) %>% 
  select(-ghm__) -> libelle_long

v %>% filter(stringr::str_detect(x, rrracine)) -> w

w$x %>% stringr::str_replace_all('\\s{3,}', '@#') %>% 
  stringr::str_split("@#", simplify = T) %>% 
  as.data.frame() -> temp

# Décalage une colonne à droite non
temp[temp$V1 == "",] %>% select(-V1) %>% as.matrix() -> one
# Décalage une colonne à droite oui
temp[temp$V1 != "",] %>% select(-V9) %>% as.matrix() -> two

# Rassemblement
rbind(one, two) -> three

# Quelles colonnes sont non vides et nombre de colonnes non vides
three %>% 
  as_tibble() %>% 
  mutate(i_5 = (V5 != ""),
         i_6 = (V6 != ""),
         i_7 = (V7 != ""),
         i_8 = (V8 != ""),
         i_9 = (V9 != ""),
         test = i_5 + i_6 + i_7 + i_8 + i_9) -> four

# Différentes situations / différentes stratégies
unique(four$test)

# 3 colonnes remplies : borne haute, tarif de base et tarif borne haute
four %>% 
  filter(test == 3) %>% 
  mutate(bh = V5,
         tbase = V6,
         th = V7,
         tb = "",
         bb = "") -> borne_hautes

# 5 colonnes remplies : borne haute, tarif de base et tarif borne haute + borne basse et tarif borne basse
four %>% 
  filter(test == 5) %>% 
  mutate(bh = V6,
         tbase = V7,
         th = V9,
         tb = V8,
         bb = V5) -> borne_bases

# 1 colonne remplie : tarif de base
four %>% 
  filter(test == 1) %>% 
  mutate(bh = "",
         tbase = V5,
         th = "",
         tb = "",
         bb = "") -> base

# 0 colonne remplie : tarif de base pour le décalage à droite
four %>% 
  filter(test == 0) %>% 
  mutate(bh = "",
         tbase = V4,
         th = "",
         tb = "",
         bb = "") -> base_2

# 2 colonnes remplies : borne haute, tarif de base et tarif borne haute pour le décalage à droite
four %>% 
  filter(test == 2) %>% 
  mutate(bh = V4,
         tbase = V5,
         th = V6,
         tb = "",
         bb = "") -> borne_hautes_2

# 4 colonnes remplies : tout est remplie mais décalage à droite
four %>% 
  filter(test == 4) %>% 
  mutate(bh = V5,
         tbase = V6,
         th = V8,
         tb = V7,
         bb = V4) -> borne_bases_2

# Rassemblement
suppressWarnings(bind_rows(borne_hautes, borne_hautes_2, borne_bases, borne_bases_2, base, base_2) -> fin)

# Renommage et mise au format numérique
fin %>% 
  select(ghs = V2,
         ghm = V3,
         lib_ghs = V4,
         bb, bh, tbase, tb, th) %>% 
  mutate(bb = parse_number(bb),
         bh = parse_number(bh),
         tbase = parse_number(tbase, locale = locale(decimal_mark = ",", grouping_mark = " ")),
         tb = parse_number(tb, locale = locale(decimal_mark = ",", grouping_mark = " ")),
         th = parse_number(th, locale = locale(decimal_mark = ",", grouping_mark = " "))) -> fin_2

# Pour le décalage, on re-extrait le ghm, et le libellé et mise en forme du ghs sur 4 car.
fin_2 %>% 
  mutate(gghm = stringr::str_extract(ghm, rrracine),
         lib_ghs = ifelse(ghm != gghm, stringr::str_replace(ghm, rrracine, ''), lib_ghs),
         ghm = gghm) %>% 
  select( - gghm) %>% 
  mutate(ghs = sprintf('%04d', as.integer(ghs)))-> tarif_ghs

# Ajout des libellés avec saut de ligne
tarif_ghs %>% left_join(libelle_long %>% 
                          distinct(ghm_, .keep_all = T) %>% select(ghm_, lib_suite), by = c('ghm' = 'ghm_')) %>% 
  mutate(lib_ghs = paste(lib_ghs, ifelse(is.na(lib_suite), "", stringr::str_trim(lib_suite)), sep = " ")) %>% 
  select(- lib_suite) -> tarif_ghs

# voir et exporter la table
DT::datatable(tarif_ghs, extensions = 'Buttons', options = list(
  dom = 'Bfrtip',
  buttons = c('copy', 'csv', 'excel', 'pdf', 'print'))
)



# Vérification avec la table "officielle" atih ghs_pub_2017.csv
library(requetr)
get_table('tarifs_mco_ghs')  %>% as_tibble() %>% filter(anseqta == '2017') -> atih

# diff base
full_join(
  select(atih, ghs, ghm, tarif_base),
  select(tarif_ghs, ghs, ghm, tbase),
  suffix = c('_atih', '_pdf')
) %>% mutate(id = tbase == tarif_base,
             diff = tbase - tarif_base)-> test

distinct(test, ghm, ghs)
sum(test$diff, na.rm = T)

# diff bh
full_join(
  select(atih, ghs, ghm, borne_haute),
  select(tarif_ghs, ghs, ghm, bh),
  suffix = c('_atih', '_pdf')
) %>% mutate(id = borne_haute == bh,
             diff = borne_haute - bh)-> test

distinct(test, ghm, ghs)
sum(test$diff, na.rm = T)

# diff bb
full_join(
  select(atih, ghs, ghm, borne_basse),
  select(tarif_ghs, ghs, ghm, bb),
  suffix = c('_atih', '_pdf')
) %>% mutate(id = borne_basse == bb,
             diff = borne_basse - bb)-> test

distinct(test, ghm, ghs)
sum(test$diff, na.rm = T)
 
# diff tarif_exb
full_join(
  select(atih, ghs, ghm, tarif_exb),
  select(tarif_ghs, ghs, ghm, tb),
  suffix = c('_atih', '_pdf')
) %>% mutate(id = tarif_exb == tb,
             diff = tarif_exb - tb)-> test

distinct(test, ghm, ghs)
sum(test$diff, na.rm = T)

# diff tarif_exh
full_join(
  select(atih, ghs, ghm, tarif_exh),
  select(tarif_ghs, ghs, ghm, th),
  suffix = c('_atih', '_pdf')
) %>% mutate(id = tarif_exh == th,
             diff = tarif_exh - th)-> test

distinct(test, ghm, ghs)
sum(test$diff, na.rm = T)
