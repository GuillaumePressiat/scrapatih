---
title: Scrapatih
date: 4 octobre 2017
author: Guillaume Pressiat
--- 


## Projet pour récupérer les listes (diagnostics, actes) des manuels de ghm et de gme.

#### Présentation générale
	
- Les pdf volume 2 des manuels de ghm / gme sont téléchargés automatiquement depuis le site du ministère en début de programme
- leur contenu est sauvegardé au format txt
- CMD par CMD les informations suivantes sont extraites puis rassemblées dans une seule table 
- les listes de diagnostics et de codes actes et les racines de ghm / gn vers lesquelles elles orientent (volume 2)
- la table résultat est exportée au format csv
	
#### Années prises en charge :

- MCO : ok de 2011 à 2017 (pas dispo avant sur le site solidarites-sante.gouv)
- SSR : Ok de 2015 à 2017 (pas dispo avant sur le site solidarites-sante.gouv)

*Attention il s'agit bien des listes présentes dans les pdf, donc les listes en cours au mois de mars de 
l'année N (les sources de la FG peuvent évoluer en cours d'année, ces listes avec).*

#### Packages utilisés

- [pdftools](https://cran.r-project.org/web/packages/pdftools/index.html)
- [stringr](https://cran.r-project.org/web/packages/stringr/index.html)
- [dplyr](https://cran.r-project.org/web/packages/dplyr/index.html)
- [pmeasyr](https://github.com/IM-APHP/pmeasyr)


### à faire

- Poursuivre l'extraction automatique sur le volume 1

