# Data Sources

This project uses open data published by the **Institut national de santé
publique du Québec (INSPQ)**, freely available from their COVID-19 data
archives page.

---

## Source page

All files are referenced from :

**https://www.inspq.qc.ca/covid-19/donnees/archives**

---

## Files used in v1.0

The dashboard loads 8 CSV files directly from the INSPQ servers via
`Web.Contents()`, so the data refreshes automatically whenever the source
files are updated.

| Wave code | Period | URL |
|---|---|---|
| `V1` | Feb. 23, 2020 → Aug. 22, 2020 | [PL_AGE_SEXE_v1.csv](https://www.inspq.qc.ca/sites/default/files/covid/donnees/archives/PL_AGE_SEXE_v1.csv) |
| `V2` | Aug. 23, 2020 → Mar. 20, 2021 | [PL_AGE_SEXE_v2.csv](https://www.inspq.qc.ca/sites/default/files/covid/donnees/archives/PL_AGE_SEXE_v2.csv) |
| `V3` | Mar. 21, 2021 → Jul. 17, 2021 | [PL_AGE_SEXE_v3.csv](https://www.inspq.qc.ca/sites/default/files/covid/donnees/archives/PL_AGE_SEXE_v3.csv) |
| `V4` | Jul. 18, 2021 → Dec. 4, 2021 | [PL_AGE_SEXE_v4.csv](https://www.inspq.qc.ca/sites/default/files/covid/donnees/archives/PL_AGE_SEXE_v4.csv) |
| `V5` | Dec. 5, 2021 → Mar. 12, 2022 | [PL_AGE_SEXE_v5.csv](https://www.inspq.qc.ca/sites/default/files/covid/donnees/archives/PL_AGE_SEXE_v5.csv) |
| `V6` | Mar. 13, 2022 → May 28, 2022 | [PL_AGE_SEXE_v6.csv](https://www.inspq.qc.ca/sites/default/files/covid/donnees/archives/PL_AGE_SEXE_v6.csv) |
| `V7` | May 29, 2022 → Sep. 3, 2022 | [PL_AGE_SEXE_v7.csv](https://www.inspq.qc.ca/sites/default/files/covid/donnees/archives/PL_AGE_SEXE_v7.csv) |
| `END` | Sep. 4, 2022 → Sep. 3, 2023 | [PL_AGE_SEXE_end.csv](https://www.inspq.qc.ca/sites/default/files/covid/donnees/archives/PL_AGE_SEXE_end.csv) |

**Note on dates** : the exact start/end dates of each wave are as defined
by the INSPQ. They reflect epidemiological criteria (rise / fall of incidence)
rather than calendar boundaries.

---

## Files NOT included in v1.0

The following files exist on the INSPQ portal but are not included in this
version because they use a **different column structure** that does not match
the V1-V7 / END pattern :

| File | Reason for exclusion |
|---|---|
| `PL_AGE_SEXE_saison2324.csv` | Different column layout — planned for v1.1 |
| `PL_AGE_SEXE_saison2425.csv` | Different column layout — planned for v1.1 |

Their URLs use a different path prefix :
- `https://www.inspq.qc.ca/sites/default/files/2025-07/PL_AGE_SEXE_saison2324.csv`
- `https://www.inspq.qc.ca/sites/default/files/2025-10/PL_AGE_SEXE_saison2425.csv`

---

## File structure (V1-V7 / END)

Each file contains the same column structure :

| Position | Column name | Content |
|---|---|---|
| 1 | `Groupe d'âge` | Age group (e.g. "0-9 ans", "10-19 ans", ..., "Inconnu") |
| 2-10 | Cases block | F/H/UNK counts, percentages, rates per 100,000 |
| 11-13 | Recoveries block | F/H/Total counts only |
| 14-22 | Deaths block | F/H/UNK counts, percentages, rates per 100,000 |
| 23-31 | Total hospitalizations block | F/H/UNK counts, percentages, rates per 100,000 |
| 32-40 | ICU hospitalizations block | F/H/UNK counts, percentages, rates per 100,000 |
| 41-49 | Non-ICU hospitalizations block | F/H/UNK counts, percentages, rates per 100,000 |

**Important** : multiple columns share the same name (e.g. `% F CUMUL` appears
5 times — once per rich indicator). This forces a position-based approach
in Power Query rather than name-based.

For technical details on how this structure is handled, see
[`docs/architecture.md`](../docs/architecture.md).

---

## Data file format

- **Encoding** : UTF-8 (code page 65001)
- **Delimiter** : comma (`,`)
- **Decimal separator** : period (`.`)
- **Headers** : first row contains column labels, but **deliberately ignored**
  by the M code due to ambiguity (see architecture document)
- **Total / summary rows** : present at the end of each file, filtered out
  by an explicit whitelist of valid age groups

---

## Data usage and license

The INSPQ COVID-19 open data are publicly available under the
**Open data terms of use** of the Government of Québec.

This project is an independent analytical work using these data ; it is not
affiliated with, endorsed by, or otherwise connected to the INSPQ.

Refer to the INSPQ portal for official information on data licensing and
terms of use.

---

## Refreshing the data

To refresh data in Power BI Desktop :

1. Open the `.pbix` file
2. Click **Home → Refresh**
3. Power BI will re-download all 8 CSV files from INSPQ
4. The model rebuilds automatically using the M code

No local files need to be downloaded — the entire pipeline runs from URLs.
