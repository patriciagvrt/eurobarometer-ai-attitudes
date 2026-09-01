# Codebook notes

Working notes on variable selection, coding decisions, and missing-value handling. Update as you verify each variable against the GESIS variable report.

---

## Weights

| Variable | Use |
|---|---|
| `w1` | National post-stratification weight. Country-level analysis and within-country descriptives. |
| `w1de` | Adjusts East and West Germany to true united-Germany proportions. Use when analysing Germany as a whole. |
| EU27 total weight | Pooled EU27 estimates. Rescales each country by its population share aged 15+. Verify the exact variable name in the variable report. |
| `wex` | Extrapolated weight for population-projected counts. Not used for proportions or regression. |

All estimates in this analysis are weighted. Unweighted figures appear only as robustness checks.

---

## Dependent variables

### `qb5` — Overall perception of robots and AI in the workplace

Trend item, also fielded in EB 87.1 (2017).

- **Scale direction:** verify before dichotomising. Confirm whether low values indicate positive or negative perception.
- **Missing codes:** to be confirmed in the variable report.
- **Derived variable:** `ai_positive`, binary, 1 if positive perception.

### `qb6_1` to `qb6_9` — Agreement battery

Nine statements on AI and employment, including job displacement, need for careful management, and effects on work pace and communication.

- **Missing codes:** DK typically coded as the final category. Confirm per item.
- Some items are reverse-worded. Check direction before constructing any index.

### `qb8_1` to `qb8_8` — Perception of specific AI applications

Eight workplace uses, from safety improvement to automated dismissal.

---

## Independent variables

### `d8` — Age when stopped full-time education

Used as the education proxy. Eurobarometer does not collect ISCED levels.

| Code | Meaning |
|---|---|
| 00 | Still studying |
| 01 | No full-time education |
| 98 | Refusal |
| 99 | Don't know |

Recoded into `edu_group`: Low (up to 15), Medium (16 to 19), High (20+), Still studying. Refusals and DK set to `NA`.

### `d60` — Difficulty paying bills

Proxy for financial precarity.

| Code | Meaning |
|---|---|
| 1 | Most of the time |
| 2 | From time to time |
| 3 | Almost never / never |
| 4 | Refusal / DK |

Code 4 set to `NA`. Recoded into `precarity`.

### `d25` — Type of community

| Code | Meaning |
|---|---|
| 1 | Rural area or village |
| 2 | Small or medium-sized town |
| 3 | Large town |
| 4 | Don't know |

Code 4 set to `NA`.

### Other demographics

| Variable | Content |
|---|---|
| `d10` | Gender |
| `d11` | Exact age, numeric |
| `d15a` | Current occupation |
| `d15b` | Last occupation, if not currently working |
| `isocntry` | Country, ISO alpha-2, with DE-E / DE-W split |

---

## Open items to verify

- [ ] Exact suffixes for `qb6_*`, `qb7_*`, `qb8_*` in the .sav file
- [ ] Direction of the `qb5` scale
- [ ] DK code for each QB item
- [ ] Exact variable name of the EU27 total weight
- [ ] Whether `d63` (subjective social class) is present in this wave

---

## Notes on interpretation

EB 554 does not include a dedicated trust-in-AI battery or a general AI awareness item. The closest available constructs are perception (`qb5`), agreement statements (`qb6`), and workplace exposure (`qb7`). Claims about trust or AI literacy should not be made from this dataset without qualification.
