---
title: Scrapatih
date: 13 mars 2018
author: Guillaume Pressiat
--- 

## Scrapatih : récupérer les listes (diagnostics, actes) des manuels et notices atih au format pdf.

### Documents pris en charge

#### Volume 2 des manuels de ghm / gme
	
##### Principe

- Les pdf volume 2 des manuels de [ghm](http://solidarites-sante.gouv.fr/fichiers/bos/2016/sts_20160005_0002_p000.pdf) / [gme](http://solidarites-sante.gouv.fr/fichiers/bos/2016/sts_20160001_0002_p000.pdf) sont téléchargés automatiquement depuis le site du ministère en début de programme
- leur contenu est sauvegardé au format txt
- CMD par CMD les informations suivantes sont extraites puis rassemblées dans une seule table 
- les listes de diagnostics et de codes actes et les racines de ghm / gn vers lesquelles elles orientent (volume 2)
- la table résultat est exportée au format csv
	
##### Années prises en charge :

- MCO : de 2011 à 2017 (pas dispo avant sur le site solidarites-sante.gouv)
- SSR : de 2015 à 2017 (pas dispo avant sur le site solidarites-sante.gouv)

*Attention il s'agit bien des listes présentes dans les pdf, donc les listes en cours au mois de mars de 
l'année N (les sources de la FG peuvent évoluer en cours d'année, ces listes avec).*

	
##### Programmes

```
pgm/mco/prog1b_propre.R
pgm/ssr/prog1_propre.R
```

#### Tarifs GHS du journal officiel (articles a,b,c, ou article d)

##### Principe

Chaque année en mars les tarifs sont publiés au format pdf, ces programmes permettent de récupérer les tarifs de base, bornes basse et haute, tarifs exb, exh, et forfait exb (pour 2016) par couple de ghs / ghm / libellés .

Les programmes fonctionnent donc de 2016 à maintenant.

##### Programmes

```
pgm/mco/prog_ghs.R
pgm/mco/prog_ghs_forfait_exb_2016.R
```

#### Listes en annexes des Indicateurs de Performance et d'Activité ([IPA](http://www.atih.sante.fr/indicateurs-de-pilotage-de-l-activite-ipa))
  

Sur le même principe d'extraction que pour le volume 2 des manuels de ghm / gme, de 2011 à 2017, les annexes sont récupérées automatiquement au format csv :

- Annexe 1 - Liste des actes relevant de la neurochirurgie
- Annexe 2 - Liste des actes relevant de la neuroradiologie
- Annexe 3 - Liste des actes relevant de la cardiologie interventionnelle

##### Programme

```
pgm/mco/prog_ipa.R
```

### Packages utilisés

- [pdftools](https://cran.r-project.org/web/packages/pdftools/index.html)
- [stringr](https://cran.r-project.org/web/packages/stringr/index.html)
- [dplyr](https://cran.r-project.org/web/packages/dplyr/index.html)
- [tidyr](https://cran.r-project.org/web/packages/tidyr/index.html)
- [purrr](https://cran.r-project.org/web/packages/purrr/index.html)
- [pmeasyr](https://github.com/IM-APHP/pmeasyr)


### à faire

- Poursuivre l'extraction automatique sur le volume 1 des manuels de ghm

