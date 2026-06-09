# Technical Architecture

This document describes the technical architecture of the COVID-19 Québec
Power BI dashboard, focusing on the data pipeline, the star schema model,
and the key design decisions.

---

## 1. Data Pipeline Overview

The end-to-end data flow is structured in three layers :

```
RAW LAYER                    TRANSFORMATION LAYER              MODEL LAYER
─────────                    ─────────────────────              ───────────
8 CSV files                  6 indicators × 8 waves             1 fact table
from INSPQ          ───►     stacked into uniform      ───►    + 4 dimension
(loaded via                   long-format tables                tables
 Web.Contents)                                                  (star schema)
```

### Layer 1 — Raw load (8 queries)

Each wave file is loaded into its own raw query (`PL_v1_brut`, `PL_v2_brut`,
..., `PL_end_brut`), with two key decisions :

1. No header promotion : Power Query's `Table.PromoteHeaders` is
   deliberately NOT used, because the source files contain duplicate column
   names (`% F CUMUL` appears 5 times). Promoting would create ambiguous
   `.1`, `.2` suffixes that depend on Power Query's deduplication algorithm.
   Instead, columns stay as `Column1`, `Column2`, ..., which are positional
   and stable.

2. First row dropped : the header row is removed via `Table.Skip(Source, 1)`,
   so we work directly with data rows.

### Layer 2 — Restructuring (2 reusable functions)

Two parameterized M functions handle the entire restructuring logic :

#### `fnBloc(src, p, indicator)`

Handles "rich" indicators (5 of the 6) where each block follows a 9-column
pattern :

| Position | Content |
|---|---|
| `p` | Female count |
| `p+1` | Female percentage |
| `p+2` | Female rate per 100,000 |
| `p+3` | Male count |
| `p+4` | Male percentage |
| `p+5` | Male rate per 100,000 |
| `p+6` | Unknown-sex count |
| `p+7` | Total count (excluded — recomputed by DAX) |
| `p+8` | Total rate (excluded — recomputed by DAX) |

The function builds three sub-tables (F, H, UNK) by selecting columns
positionally, renames them to a standard schema, stacks them, and tags
with the indicator name.

#### `fnBlocRetablis(src)`

Handles the special "recoveries" block, which has only 3 columns
(female count, male count, total count) with no percentages, no rates,
and no unknown-sex category.

### Layer 3 — Wave assembly (8 queries)

For each wave, a `Vague_Vx` query calls `fnBloc` five times (one per rich
indicator) plus `fnBlocRetablis` once, then stacks all six results and
appends two contextual columns :

- `Vague` : the wave code (`V1`, `V2`, ..., `END`)
- `Date_Debut_Vague` : the official start date

### Layer 4 — Unified fact table

The final `FAITS_COVID` table is built by stacking the 8 wave tables :

```powerquery
FAITS_COVID = Table.Combine({
    Vague_V1, Vague_V2, Vague_V3, Vague_V4,
    Vague_V5, Vague_V6, Vague_V7, Vague_END
})
```

Resulting in approximately **1 500 rows** with the following schema :

| Column | Type | Description |
|---|---|---|
| `Groupe_Age` | Text | Age group label (e.g. "0-9 ans") |
| `Code_Age` | Text | Sortable age code (e.g. "AGE_00_09") |
| `Nombre` | Whole number | Cumulative count |
| `Pourcentage` | Decimal | Cumulative percentage |
| `Taux_100000` | Decimal | Rate per 100,000 population |
| `REF_SEXE` | Text | Sex code (F, H, UNK) |
| `Indicateur` | Text | Indicator name |
| `Vague` | Text | Wave code |
| `Date_Debut_Vague` | Date | Wave start date |

---

## 2. Star Schema Model

### Why star schema ?

The choice of a star schema (rather than a snowflake or flat table) is
deliberate :

- Performance : star schemas are optimized for analytical queries,
  with small dimension tables joined to a large fact table
- Clarity : the model is immediately understandable by anyone familiar
  with BI patterns
- Filterability : Power BI's filter propagation works seamlessly across
  dimensions, enabling intuitive slicing
- Industry standard : recruiters and BI professionals expect this pattern

### The four dimensions

#### DIM_GROUPE_AGE (11 rows)

| Column | Purpose |
|---|---|
| `Code_Age` | Primary key (links to fact table) |
| `Libelle_Age` | Display label |
| `Ordre_Age` | Sort order (1-10 for real groups, 99 for "Unknown") |

The `Ordre_Age = 99` convention ensures the "Unknown" category always
appears last in visualizations, regardless of where it would fall
alphabetically.

#### DIM_SEXE (3 rows)

| Column | Purpose |
|---|---|
| `REF_SEXE` | Primary key |
| `Libelle_Sexe` | Display label |
| `Ordre_Sexe` | Sort order |

#### DIM_VAGUE (8 rows)

| Column | Purpose |
|---|---|
| `Vague` | Primary key |
| `Libelle_Vague` | Display label with date context |
| `Date_Debut` | Start date of the period |
| `Type_Periode` | Category (Wave / Endemic) |
| `Ordre_Vague` | Sort order |

The `Type_Periode` column enables a powerful slicing : comparing the active
wave periods against the transitional endemic phase in a single click.

#### DIM_INDICATEUR (6 rows)

| Column | Purpose |
|---|---|
| `Indicateur` | Primary key |
| `Libelle_Indicateur` | Display label |
| `Categorie` | Grouping (Infection / Severity / Hospitalization / Recovery) |
| `Ordre_Indicateur` | Sort order |

The `Categorie` column allows grouping the three hospitalization indicators
(total, ICU, non-ICU) in visualizations.

### Relationships

All four relationships are **Many-to-One**, **single-direction**, from
`FAITS_COVID` to each dimension :

| Fact column | → | Dimension key |
|---|---|---|
| `Code_Age` | → | `DIM_GROUPE_AGE.Code_Age` |
| `REF_SEXE` | → | `DIM_SEXE.REF_SEXE` |
| `Vague` | → | `DIM_VAGUE.Vague` |
| `Indicateur` | → | `DIM_INDICATEUR.Indicateur` |

---

## 3. Key Design Decisions

### Why not unpivot all measures into a single value column ?

A common alternative would be to fully unpivot the data into a triple
`(Groupe_Age, REF_SEXE, Mesure, Valeur)` format. While more compact, it
would mix counts, percentages, and rates in a single column, requiring
explicit filtering in every visualization.

The current design — keeping `Nombre`, `Pourcentage`, and `Taux_100000`
as separate columns — keeps the semantic distinction clear and simplifies
DAX measure writing.

### Why exclude total and total-rate columns from each block ?

The source files include pre-computed totals (`Cas total CUMUL`,
`Taux pour 100 000 CUMUL`) for each indicator. These were intentionally
excluded because :

1. Risk of double-counting : keeping them as rows would inflate sums
2. Best practice : totals should be recomputed by DAX, which guarantees
   consistency with the current filter context
3. Cleaner model : the fact table contains only atomic measures

### Why an explicit list of valid age groups instead of `Table.RemoveLastN` ?

An earlier version used `Table.RemoveLastN(table, 3)` to drop trailing
rows (totals, notes, blanks). This was replaced by an explicit filter on
a whitelist of valid age group labels, because :

- Robustness : works regardless of how many trailing rows a file has
- Self-documenting : the code immediately shows which categories are
  considered valid
- Bug-resistant : if a future file has different trailing content,
  the filter still works correctly

---

## 4. Scope Limitations and Future Work

### What is NOT in v1.0

- 2023-2024 and 2024-2025 seasons : these later files use a different
  column structure that does not match the V1-V7 + END pattern. Including
  them requires writing an adapted function — planned for v1.1.

- Regional breakdown : the current model is province-wide. INSPQ also
  publishes data by health region, which could be integrated with an
  additional `DIM_REGION` dimension.

- Daily granularity : the source files are cumulative snapshots, not
  time series. For day-by-day evolution, a different set of INSPQ files
  would need to be integrated.

### What v1.1 will add

- Adapted function for the 2023-2025 seasons
- Extended `DIM_VAGUE` with the new periods
- Cross-period comparisons between wave-era and seasonal-era patterns

---

## 5. References

- Microsoft Power Query M reference :
  https://learn.microsoft.com/en-us/powerquery-m/
- INSPQ COVID-19 open data :
  https://www.inspq.qc.ca/covid-19/donnees/archives
- Star schema design (Kimball methodology) :
  https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/
