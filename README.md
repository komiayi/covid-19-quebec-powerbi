# COVID-19 Quebec Dashboard — Wave-by-Wave Analysis

[![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=flat&logo=powerbi&logoColor=black)](https://powerbi.microsoft.com/)
[![Power Query](https://img.shields.io/badge/Power%20Query-M-blue)](https://learn.microsoft.com/en-us/powerquery-m/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-v1.0-brightgreen)]()

Interactive Power BI dashboard analyzing the COVID-19 pandemic in Québec
across the first 7 waves and the transitional endemic period
(February 2020 – September 2023), using open data from the
**Institut national de santé publique du Québec (INSPQ)**.

---

## 🎯 Project Objective

Compare six key health indicators (confirmed cases, deaths, three types of
hospitalizations, recoveries) by **age group**, **sex** and **pandemic period**,
to identify the most vulnerable populations and track epidemiological trends
over time.

---

## 📊 Data Source

All data comes from the **INSPQ COVID-19 open data archives** :

- **Reference page** : [inspq.qc.ca/covid-19/donnees/archives](https://www.inspq.qc.ca/covid-19/donnees/archives)
- **Files used** : 8 CSV files (`PL_AGE_SEXE_v1.csv` through `v7.csv` + `PL_AGE_SEXE_end.csv`)
- **Period covered** : February 23, 2020 → September 3, 2023
- **Granularity** : cumulative counts by age group and sex per wave
- **Format** : comma-delimited CSV, UTF-8 encoding

See [`data/sources.md`](data/sources.md) for the complete list of source URLs.

---

## 🏗️ Technical Architecture

### Star schema model

The data model follows the **star schema pattern** with one fact table at
the center and four dimension tables around it :

```
              DIM_VAGUE
                  │
                  │
DIM_GROUPE_AGE ── FAITS_COVID ── DIM_SEXE
                  │
                  │
            DIM_INDICATEUR
```

| Table | Type | Rows | Description |
|---|---|---|---|
| `FAITS_COVID` | Fact | ~1 500 | Unified long-format table containing all measures |
| `DIM_GROUPE_AGE` | Dimension | 11 | Age groups with display labels and sort order |
| `DIM_SEXE` | Dimension | 3 | Sex categories (Female, Male, Unknown) |
| `DIM_VAGUE` | Dimension | 8 | Pandemic waves with start dates and period type |
| `DIM_INDICATEUR` | Dimension | 6 | Health indicators with category grouping |

See [`docs/architecture.md`](docs/architecture.md) for detailed architecture
documentation and design decisions.

### Main technical challenge

The INSPQ source files present a deliberately tricky structure :

- **Duplicate column names** : `% F CUMUL`, `Sexe inconnu CUMUL` and others
  appear up to 5 times in the same file
- **Encoded attributes in headers** : sex is embedded in column names
  (`Cas F CUMUL`, `Cas H CUMUL`) instead of being a proper variable
- **Position-dependent semantics** : the indicator (cases, deaths,
  hospitalizations) can only be inferred from column position, not from name

### Solution : reusable parameterized M functions

Rather than hard-coding cleanup for each block, I developed two reusable
Power Query M functions that restructure any indicator block from its
starting position :

- **`fnBloc(src, p, indicator)`** : handles "rich" indicators (9 columns
  per block : F/H/UNK counts with percentages and rates)
- **`fnBlocRetablis(src)`** : handles the special case of recoveries
  (3 columns : F/H/Total counts only, no percentages or rates)

Both functions produce a clean long-format output with a consistent schema,
ready for stacking into the unified fact table.

See [`powerquery/`](powerquery/) for the complete function code.

---

## 🛠️ Technologies & Skills Demonstrated

| Skill area | Specifics |
|---|---|
| **Power BI Desktop** | Report design, modeling, DAX measures |
| **Power Query (M)** | Reusable parameterized functions, dynamic column references, conditional logic |
| **Data modeling** | Star schema design, dimension tables with sort orders, long-format normalization |
| **Data cleaning** | Position-based extraction, duplicate header handling, type conversion, explicit row filtering |
| **DAX** | Calculated measures, time intelligence, contextual aggregations |
| **Documentation** | Reproducible code, traceable transformations, README-driven design |

---

## 📁 Repository Structure

```
covid-19-quebec-powerbi/
│
├── README.md                          ← You are here
├── LICENSE                            ← MIT license
├── .gitignore                         ← Excludes temp files
│
├── powerbi/
│   └── covid_quebec.pbix              ← Power BI report file
│
├── docs/
│   ├── architecture.md                ← Detailed technical architecture
│   ├── star_schema.png                ← Visual of the data model
│   └── dashboard_preview.png          ← Dashboard screenshots
│
├── data/
│   └── sources.md                     ← INSPQ source URLs
│
└── powerquery/
    ├── fnBloc.pq                      ← Main M function
    ├── fnBlocRetablis.pq              ← Recoveries M function
    ├── PL_v1_brut.pq                  ← Raw load example (wave 1)
    └── Vague_V1.pq                    ← Wave processing example
```

---

## 🚀 Getting Started

### Prerequisites

- **Power BI Desktop** (free version) — [Download here](https://powerbi.microsoft.com/desktop/)
- Or **Power BI Service** account to view a published version (link coming in v1.1)

### Open the project

1. Clone or download this repository
2. Open `powerbi/covid_quebec.pbix` in Power BI Desktop
3. The model loads data directly from INSPQ URLs — no local files needed
4. Click **Refresh** to fetch the latest available data

### Inspect the Power Query code

To explore the M code directly :

1. Open Power BI Desktop with the `.pbix` file
2. Click **Transform data** to open the Power Query Editor
3. Browse the queries organized in folders (`_Fonctions`, `Vagues`, `Modèle final`)
4. Use **Advanced Editor** to view the full M code of any query

---

## 🎨 Dashboard Highlights

*[Screenshots will be added once the visualization layer is complete]*

The dashboard will include :
- **Overview tab** : key KPIs and pandemic timeline
- **Demographic analysis** : age and sex breakdowns per indicator
- **Wave comparison** : evolution from V1 through endemic transition
- **Hospitalization deep-dive** : ICU vs non-ICU patterns

---

## 🔭 Roadmap (v1.1 and beyond)

- [ ] **Visualization layer** : 3-4 thematic tabs with interactive filters
- [ ] **Publication** : deployment to Power BI Service with public sharing link
- [ ] **Extended periods** : integration of 2023-2024 and 2024-2025 seasons
      (which use a different file structure requiring an adapted function)
- [ ] **Regional analysis** : breakdown by health region using additional
      INSPQ files
- [ ] **Wastewater correlation** : cross-reference with the SARS-CoV-2
      wastewater surveillance data

---

## 📚 Background & Motivation

This project is part of a broader portfolio demonstrating my ability to
handle real-world public health data in their raw, imperfect state.
It complements my academic background in biostatistics and epidemiology
(M.Sc. Statistics, UQAM, 2025) and showcases the practical data engineering
skills that go alongside statistical modeling.

The choice of COVID-19 INSPQ data is deliberate :
- **Real public health data** at population scale
- **Genuinely messy source structure** that requires thoughtful cleanup
- **Multi-period coverage** allowing meaningful longitudinal analysis
- **Open and reproducible** — anyone can rebuild this dashboard from the URLs

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE)
file for details.

The INSPQ source data are publicly available under their own terms of use.
This project is an independent analytical work and is not affiliated with
or endorsed by the INSPQ.

---

## 👤 Author

**Komi Ayi** — Data Scientist | Biostatistics & Health Analytics

- 💼 [LinkedIn](https://www.linkedin.com/in/komi-ayi)
- 🌐 [Portfolio](https://komiayi.github.io)
- 💻 [GitHub](https://github.com/komiayi)
- 📧 ayi1rogera@gmail.com

---

## 🙏 Acknowledgments

- **INSPQ** (Institut national de santé publique du Québec) for making
  these data openly available
- **OHDSI / EHDEN community** for the OMOP CDM training that influenced
  the modeling approach
- **UQAM** Faculty of Mathematics and Statistical Sciences for the
  methodological foundation
