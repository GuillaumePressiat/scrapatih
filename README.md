---
title: Scrapatih
date: 4 octobre 2017
author: Guillaume Pressiat
--- 

# Scrapatih

## Projet pour récupérer les listes (diagnostics, actes) des manuels et notices atih au format pdf.

### Documents pris en charge

#### Volume 2 des manuels de ghm / gme
	
##### Principe

- Les pdf volume 2 des manuels de ghm / gme sont téléchargés automatiquement depuis le site du ministère en début de programme
- leur contenu est sauvegardé au format txt
- CMD par CMD les informations suivantes sont extraites puis rassemblées dans une seule table 
- les listes de diagnostics et de codes actes et les racines de ghm / gn vers lesquelles elles orientent (volume 2)
- la table résultat est exportée au format csv
	
##### Années prises en charge :

- MCO : ok de 2011 à 2017 (pas dispo avant sur le site solidarites-sante.gouv)
- SSR : Ok de 2015 à 2017 (pas dispo avant sur le site solidarites-sante.gouv)

*Attention il s'agit bien des listes présentes dans les pdf, donc les listes en cours au mois de mars de 
l'année N (les sources de la FG peuvent évoluer en cours d'année, ces listes avec).*

#### Listes en annexes des Indicateurs de Performance et d'Activité (IPA)
  

Sur le même principe d'extraction que pour le volume 2 des manuels de ghm / gme, de 2011 à 2016, les annexes sont récupérées automatiquement au format csv :

- Annexe 1 - Liste des actes relevant de neurochirurgie
- Annexe 2 - Liste des actes relevant de la neuroradiologie
- Annexe 3 - Liste des actes relevant de la cardiologie interventionnelle

### Packages utilisés

- [pdftools](https://cran.r-project.org/web/packages/pdftools/index.html)
- [stringr](https://cran.r-project.org/web/packages/stringr/index.html)
- [dplyr](https://cran.r-project.org/web/packages/dplyr/index.html)
- [tidyr](https://cran.r-project.org/web/packages/tidyr/index.html)
- [purrr](https://cran.r-project.org/web/packages/purrr/index.html)
- [pmeasyr](https://github.com/IM-APHP/pmeasyr)


### à faire

- Poursuivre l'extraction automatique sur le volume 1 des manuels de ghm

