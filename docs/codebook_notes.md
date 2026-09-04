# Codebook notes

Variable names and value codes verified directly against the ZA8844 `.sav` file metadata (dataset version 1.0.0, 7 May 2025). Dataset contains **26,404 respondents** and **349 variables** across 28 country samples (EU27, with Germany split East/West).

---

## Weights

Fifteen weight variables are supplied. The relevant ones for this project:

| Variable | Label | Use |
|---|---|---|
| `w1` | WEIGHT RESULT FROM TARGET (REDRESSMENT) | National post-stratification weight. Reproduces real case numbers per country. East and West Germany weighted separately. **Use for country-level analysis.** |
| `w1de` | WEIGHT RESULT FROM TARGET - GERMANY | Adjusts East and West German samples to their proportions in united Germany. Use when analysing Germany as a whole. |
| `w22` | WEIGHT EU27 | **Use for pooled EU27 estimates.** Mean = 1.0. |
| `w92` | WEIGHT TOTAL (ALL SAMPLES) | All samples combined, EU28 minus UK. |

GESIS recommends post-stratification weights for descriptive analysis, and population-size weights for country groups or countries with separate samples.

---

## Dependent variables

### `qb5` — ROBOTS - GENERAL PERCEPTION IN WORKPLACE

Trend item, partly replicating Eurobarometer 87.1 (ZA6861, 2017).

| Code | Label |
|---|---|
| 1 | Very positively |
| 2 | Fairly positively |
| 3 | Fairly negatively |
| 4 | Very negatively |
| 5 | Don't know (spontaneous) |

Scale runs positive to negative. Code 5 recoded to `NA`. Derived variable `ai_positive` = 1 if `qb5` is 1 or 2.

Unweighted distribution: 3,770 very positive / 12,914 fairly positive / 5,952 fairly negative / 2,117 very negative / 1,651 DK.

### `qb6_1` to `qb6_9` — Agreement battery

| Code | Label |
|---|---|
| 1 | Totally agree |
| 2 | Tend to agree |
| 3 | Tend to disagree |
| 4 | Totally disagree |
| 5 | Don't know (spontaneous) |

Items: (1) more jobs disappear than created; (2) help people in job/home; (3) require careful management; (4) do boring/repetitive jobs; (5) steal jobs; (6) increase task completion pace; (7) negative impact on communication between colleagues; (8) used to make accurate decisions; (9) should be used more widely outside workplace.

Note the mixed valence — items 1, 5, 7 are negatively worded. Reverse before constructing any index.

### `qb8_1` to `qb8_8` — Perception of specific workplace applications

Same 1–4 scale as `qb5`, with 5 = DK. Applications: gathering applicant information; selecting applicants; allocating tasks; collecting and storing personal data; improving safety; monitoring workers; assessing performance; automatically firing workers.

---

## Explanatory and control variables

### `qb2_1` to `qb2_4` — Self-rated digital skills

| Code | Label |
|---|---|
| 1 | Totally agree |
| 2 | Tend to agree |
| 3 | Tend to disagree |
| 4 | Totally disagree |
| 5 | Not applicable |
| 6 | Don't know (spontaneous) |

Domains: daily life; to do job; to do future job; to benefit from digital learning. Codes 5 and 6 recoded to `NA`. `digital_skill` = `5 - qb2_1`, so higher values mean higher self-rated skill.

### `qb7_1` to `qb7_6` — Workplace AI exposure

| Code | Label |
|---|---|
| 1 | Yes, all the time |
| 2 | Yes, often |
| 3 | No, rarely |
| 4 | No, never |
| 5 | Not applicable (spontaneous) |
| 6 | Don't know (spontaneous) |
| 9 | Inapplicable (code 15 in d15b) |

Codes 5, 6 and 9 recoded to `NA`. Derived `ai_exposure` = 1 if any item is 1 or 2.

### `qb4` — Awareness of employer AI use

Codes 1–4 run totally aware to totally unaware. Code 5 = workplace does not use digital technologies, 6 = DK, 9 = inapplicable. All three recoded to `NA`.

### `d8` — AGE EDUCATION

Education proxy. Eurobarometer does not collect ISCED levels.

| Code | Label |
|---|---|
| 0 | Refusal |
| 2–90 | Age when full-time education ended |
| 97 | No full-time education |
| 98 | Still studying |
| 99 | Don't know |

Codes 0 and 99 recoded to `NA`. Codes 97 and 98 kept as separate categories in `edu_group`, but excluded from the ordered education comparison in plots.

**Caution flagged by GESIS:** 384 respondents report "Student" in `d15a` while giving an answer other than "Still studying" in `d8`. This matches the official Excel volumes and is not an error to correct.

### `d10` — GENDER

| Code | Label |
|---|---|
| 1 | Man |
| 2 | Woman |
| 3 | Non-binary / prefer not to say |

GESIS collapsed the original categories 3 and 4 to preserve anonymity. Code 3 has too few cases for stable estimation and is set to `NA` in models.

### `d11` — AGE EXACT

Numeric. No recoding needed.

### `d25` — TYPE OF COMMUNITY

| Code | Label |
|---|---|
| 1 | Rural area or village |
| 2 | Small or middle sized town |
| 3 | Large town |
| 8 | DK (spontaneous) |

Code 8 recoded to `NA`.

### `d60` — DIFFICULTIES PAYING BILLS - LAST YEAR

Financial precarity proxy.

| Code | Label |
|---|---|
| 1 | Most of the time |
| 2 | From time to time |
| 3 | Almost never / never |
| 7 | Refusal (spontaneous) |

Code 7 recoded to `NA`. Note the code is 7, not 4 as in some earlier waves.

### `d63` — SOCIAL CLASS - SELF-ASSESSMENT (5 CAT)

| Code | Label |
|---|---|
| 1 | Working class |
| 2 | Lower middle class |
| 3 | Middle class |
| 4 | Upper middle class |
| 5 | Higher class |
| 6 | Other (spontaneous) |
| 7 | None (spontaneous) |
| 8 | Refusal (spontaneous) |
| 9 | DK (spontaneous) |

Codes 6 through 9 recoded to `NA`.

### `d15a` — OCCUPATION OF RESPONDENT

Eighteen categories from "Responsible for ordinary shopping" through "Unskilled manual worker". Full list in the variable report. `d15b` records last occupation for those not currently working.

### `isocntry` — COUNTRY CODE - ISO 3166

28 samples: EU27 with Germany split into DE-E and DE-W.

---

## Dataset caveats from the GESIS readme

- This is an **archive pre-release** (version 1.0.0). Complete variable documentation for online browsing in GESIS search is not yet available.
- **Eleven respondents were removed** due to re-identification potential. Results will deviate slightly from the official report and Excel volumes.
- For `qb1_xx` and several `qc` variables, the sequence of answer categories in the dataset diverges slightly from the questionnaire. Verian confirmed the data are correct.
- Protocol variables `p8` (postal code), `p9` (sample point), and `p10` (interviewer number) are not available.
- CAVI interviews (Czechia, Denmark, Finland, Germany, Malta) cannot be identified — no CAPI_CAVI variable exists.

---

## Notes on interpretation

EB 554 contains no dedicated trust-in-AI battery and no general AI awareness item. The available constructs are perception (`qb5`, `qb8`), agreement statements (`qb6`), self-rated skill (`qb2`), workplace exposure (`qb7`), and awareness of employer AI use (`qb4`). Claims about "trust in AI" or "AI literacy" as measured constructs should not be made from this dataset without qualification.
