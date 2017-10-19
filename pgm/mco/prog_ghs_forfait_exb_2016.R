library(pdftools)
library(dplyr, warn.conflicts = F)

# w o r k - i n - p r o g r e s s


# regexpr utile
rrracine <- '[0-9]{2}[A-Z][0-9]{2}[1234ABCDZTEJ]?'

# Télécharger le pdf du jo, 2017 ici
# https://www.legifrance.gouv.fr/jo_pdf.do?id=JORFTEXT000034203360
pdf_text('pdf/mco/joe_20160308_0057_0039.pdf') -> u

# Pour observer l'objet, fichier temp
write.table(u, 'tmp/tarifs.txt', quote = F, row.names = F, col.names = F)

# Repérer les pages avec les tarifs a, b, c  
paste(u[5:159], collapse = " ") %>% stringr::str_split(., "\\n") %>% purrr::flatten_chr() %>% tibble(x  = .) %>% 
  mutate(x = stringr::str_replace(x, 'Texte [0-9]{2,} sur [0-9]{3,}', '')) -> v

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
         i_10 = (V10 != ""),
         test = i_5 + i_6 + i_7 + i_8 + i_9 + i_10) -> four

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
         tb = V7,
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
         bb = "",
         fb = "") -> base_2

# 2 colonnes remplies : borne haute, tarif de base et tarif borne haute pour le décalage à droite
four %>% 
  filter(test == 2) %>% 
  mutate(bh = V4,
         tbase = V5,
         th = V6,
         tb = "",
         bb = "",
         fb = "") -> borne_hautes_2

# 4 colonnes remplies : tout est remplie mais décalage à droite
four %>% 
  filter(test == 4) %>% 
  mutate(bh = V5,
         tbase = V6,
         th = V7,
         tb = V8,
         bb = V4,
         fb = V8) -> borne_bases_2

# Rassemblement
suppressWarnings(bind_rows(borne_hautes, borne_hautes_2, borne_bases, borne_bases_2, base, base_2) -> fin)

# Renommage et mise au format numérique
fin %>% 
  select(ghs = V2,
         ghm = V3,
         lib_ghs = V4,
         bb, bh, tbase, tb, th, fb) %>% 
  mutate(bb = parse_number(bb),
         bh = parse_number(bh),
         tbase = parse_number(tbase, locale = locale(decimal_mark = ",", grouping_mark = " ")),
         tb = parse_number(tb, locale = locale(decimal_mark = ",", grouping_mark = " ")),
         th = parse_number(th, locale = locale(decimal_mark = ",", grouping_mark = " ")),
         fb = parse_number(fb, locale = locale(decimal_mark = ",", grouping_mark = " "))) -> fin_2

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

