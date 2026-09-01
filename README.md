# Socioeconomic Predictors of AI Attitudes in the EU

Secondary analysis of Special Eurobarometer 554 (*Artificial Intelligence and the future of work*, 2024), examining how socioeconomic and demographic factors predict attitudes toward AI in the workplace across 27 EU member states.

**Author:** Patricia Givort Cruz Cabral
**Affiliation:** MSc Computational Social Science, Linköping University
**Status:** In progress

---

## Research question

Which socioeconomic, demographic, and occupational factors predict differences in how EU citizens perceive artificial intelligence in the workplace?

Sub-questions:

1. Does education level predict positive or negative perception of workplace AI?
2. Do respondents in financially precarious situations differ in their attitudes from those who are not?
3. Does prior exposure to AI at work (algorithmic management) shift attitudes, and in which direction?
4. How much of the variation in attitudes lies between countries versus within them?

---

## Data

**Source:** Special Eurobarometer 554 / Eurobarometer 101.4 (2024)
**Archive:** GESIS Data Archive, study ZA8844
**DOI:** [10.4232/1.14471](https://doi.org/10.4232/1.14471)
**Fieldwork:** 25 April – 22 May 2024
**Sample:** 26,415 respondents across EU27
**Producer:** Verian (formerly Kantar Public), at the request of DG EMPL

The microdata are not included in this repository. GESIS terms of use prohibit redistribution. See [`data/README.md`](data/README.md) for download instructions.

### Variables used

**Dependent variables**
- `qb5` — overall perception of robots and AI in the workplace
- `qb6_*` — nine-item agreement battery on AI and employment
- `qb8_*` — perceived positivity of AI across eight workplace applications

**Independent variables**
- `d8` — age when stopped full-time education (education proxy)
- `d11` — exact age
- `d10` — gender
- `d15a` — current occupation
- `d25` — type of community (urban / rural)
- `d60` — difficulty paying bills (financial precarity proxy)
- `qb7_*` — prior exposure to AI in the workplace

**Grouping and weights**
- `isocntry` — country
- `w1` — national post-stratification weight (country-level analysis)
- EU27 total weight — pooled EU-level estimates

---

## Methods

1. Descriptive statistics, weighted, by country and by education level
2. Correlation analysis across attitude items
3. Weighted logistic regression (`survey::svyglm`) predicting positive workplace AI perception
4. Multilevel model with respondents nested in countries, to separate within- from between-country variation

All estimates are survey-weighted. Unweighted results are reported only as robustness checks.

---

## Repository structure

```
.
├── README.md                  This file
├── analysis.R                 Full analysis script
├── .gitignore                 Excludes raw data from version control
├── data/
│   └── README.md              How to obtain the dataset
├── output/
│   ├── figures/               Generated plots
│   └── tables/                Generated tables
└── docs/
    └── codebook_notes.md      Variable coding decisions and missing-value handling
```

---

## Reproducing this analysis

1. Register for a free GESIS account at [gesis.org](https://www.gesis.org)
2. Download ZA8844 in SPSS format via the DOI above
3. Place the `.sav` file in `data/`
4. Open `analysis.R` and update the filename in the read step if needed
5. Run the script

### Requirements

```r
install.packages(c("haven", "labelled", "tidyverse", "survey", "srvyr", "ggplot2"))
```

R version 4.3 or later recommended.

---

## Findings

*To be completed.*

---

## Ethics

This project analyses an already-collected, fully anonymised, publicly released dataset. No new data were collected from human participants. Under Swedish research ethics legislation and standard practice for secondary analysis of public survey archives, no separate ethical review application was required. The GESIS terms of use were accepted at download and are respected throughout.

---

## Citation

If you use this analysis, please cite the underlying dataset:

> European Commission, Brussels (2025): *Eurobarometer 101.4 (2024)*. Verian, Brussels [producer]. GESIS, Cologne. ZA8844 Data file Version 1.0.0, https://doi.org/10.4232/1.14471

---

## License

Analysis code released under the MIT License. The underlying data remain subject to GESIS terms of use.
