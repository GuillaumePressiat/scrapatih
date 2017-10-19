

library(pdftools)
library(dplyr, warn.conflicts = F)

pdf_text('pdf/mco//joe_20170317_0065_0016.pdf') -> u

write.table(u, 'tmp//tarifs.txt', quote = F, row.names = F, col.names = F)


# Reperer les pages avec les tarifs a, b, c  
paste(u[4:145], collapse = " ") %>% stringr::str_split(., "\\n") %>% purrr::flatten_chr() %>% tibble(x  = .) -> v


v %>% filter(stringr::str_detect(x, '[0-9]{2}[A-Z][0-9]{2}[1234ABCDZTEJ]?')) -> w

w$x %>% stringr::str_replace_all('\\s{3,}', '@#') %>% 
  stringr::str_split("@#", simplify = T) %>% 
  as.data.frame() -> temp

temp[temp$V1 == "",] %>% select(-V1) %>% as.matrix() -> one
temp[temp$V1 != "",] %>% select(-V9) %>% as.matrix() -> two

rbind(one, two) -> three

three[grepl('Texte', three)] <- ""

three %>% 
  as_tibble() %>% 
  mutate(i_5 = (V5 != ""),
         i_6 = (V6 != ""),
         i_7 = (V7 != ""),
         i_8 = (V8 != ""),
         i_9 = (V9 != ""),
         test = i_5 + i_6 + i_7 + i_8 + i_9) -> four

unique(four$test)

four %>% 
  filter(test == 3) %>% 
  mutate(bh = V5,
         tbase = V6,
         th = V7,
         tb = "",
         bb = "") -> borne_hautes

four %>% 
  filter(test == 5) %>% 
  mutate(bh = V6,
         tbase = V7,
         th = V8,
         tb = V9,
         bb = V5) -> borne_bases

four %>% 
  filter(test == 1) %>% 
  mutate(bh = "",
         tbase = V5,
         th = "",
         tb = "",
         bb = "") -> base


four %>% 
  filter(test == 5) %>% 
  mutate(bh = V6,
         tbase = V7,
         th = V8,
         tb = V9,
         bb = V5) -> borne_bases

four %>% 
  filter(test == 0) %>% 
  mutate(bh = "",
         tbase = V4,
         th = "",
         tb = "",
         bb = "") -> base_2

four %>% 
  filter(test == 2) %>% 
  mutate(bh = V5,
         tbase = V4,
         th = V6,
         tb = "",
         bb = "") -> borne_hautes_2
four %>% 
  filter(test == 4) %>% 
  mutate(bh = V5,
         tbase = V6,
         th = V7,
         tb = V8,
         bb = V4) -> borne_bases_2

suppressWarnings(bind_rows(borne_hautes, borne_hautes_2, borne_bases, borne_bases_2, base, base_2) -> fin)


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

fin_2 %>% 
  mutate(gghm = stringr::str_extract(ghm, '[0-9]{2}[A-Z][0-9]{2}[1234ABCDZTEJ]?'),
         lib_ghs = ifelse(ghm != gghm, stringr::str_replace(ghm, 
                                                            '([0-9]{2}[A-Z][0-9]{2}[1234ABCDZTEJ]?)', ''), lib_ghs),
         ghm = gghm) %>% 
  select( - gghm) %>% 
  mutate(ghs = sprintf('%04d', as.integer(ghs)))-> tarif_ghs



DT::datatable(tarif_ghs)