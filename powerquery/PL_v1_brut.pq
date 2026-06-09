// ============================================================================
// PL_v1_brut — Raw load query for wave 1
// ----------------------------------------------------------------------------
// Loads the COVID-19 wave 1 file from INSPQ open data, without promoting
// headers (because column names are duplicated and ambiguous), and drops
// the first row (the header text).
//
// The result is a table with columns named "Column1", "Column2", ...,
// which are positional and stable — safe to reference by position.
//
// USAGE
//   The output of this query is passed as `src` to fnBloc and fnBlocRetablis.
//
// REPLICATING FOR OTHER WAVES
//   Duplicate this query and replace only the URL :
//     - v1.csv  → V1 (Feb. 2020)
//     - v2.csv  → V2 (Aug. 2020)
//     - v3.csv  → V3 (Mar. 2021)
//     - v4.csv  → V4 (Jul. 2021)
//     - v5.csv  → V5 (Dec. 2021)
//     - v6.csv  → V6 (Mar. 2022)
//     - v7.csv  → V7 (May 2022)
//     - end.csv → END (Sep. 2022 – Sep. 2023, endemic transition)
// ============================================================================

let
    // 1. Download the CSV file from INSPQ
    Source = Csv.Document(
        Web.Contents("https://www.inspq.qc.ca/sites/default/files/covid/donnees/archives/PL_AGE_SEXE_v1.csv"),
        [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    
    // 2. Drop the first row (the text headers — ambiguous due to duplicates)
    //    Columns remain "Column1", "Column2", ... which are unique by position
    LigneIgnoree = Table.Skip(Source, 1)
in
    LigneIgnoree
