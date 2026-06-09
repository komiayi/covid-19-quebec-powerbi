// ============================================================================
// Vague_V1 — Wave 1 assembly query
// ----------------------------------------------------------------------------
// Stacks the 6 indicators of wave 1 into a single long-format table and
// adds two contextual columns (Vague, Date_Debut_Vague).
//
// This pattern is replicated for each of the 8 waves (V1 through END),
// then all wave tables are combined into the final FAITS_COVID fact table.
//
// PIPELINE
//   PL_v1_brut  ─►  fnBloc × 5 + fnBlocRetablis  ─►  Vague_V1  ─►  FAITS_COVID
//
// USAGE
//   The output of this query is one of 8 inputs to the FAITS_COVID assembly.
//
// REPLICATING FOR OTHER WAVES
//   Duplicate this query and change THREE elements only :
//     1. The source query reference (PL_v1_brut → PL_v2_brut, etc.)
//     2. The wave code in the "Vague" column ("V1" → "V2", etc.)
//     3. The start date in Date_Debut_Vague
// ============================================================================

let
    // -----------------------------
    // Stack the 6 indicators of this wave
    // -----------------------------
    // 5 rich indicators handled by fnBloc (one function call per indicator block)
    // + 1 special case for recoveries handled by fnBlocRetablis
    Empile = Table.Combine({
        fnBloc(PL_v1_brut, 2,  "Cas"),
        fnBloc(PL_v1_brut, 14, "Décès"),
        fnBloc(PL_v1_brut, 23, "Hospitalisation totale"),
        fnBloc(PL_v1_brut, 32, "Hospitalisation soins intensifs"),
        fnBloc(PL_v1_brut, 41, "Hospitalisation hors soins intensifs"),
        fnBlocRetablis(PL_v1_brut)
    }),
    
    // -----------------------------
    // Add wave code (enables filtering / comparison between waves)
    // -----------------------------
    AvecVague = Table.AddColumn(Empile, "Vague", each "V1", type text),
    
    // -----------------------------
    // Add wave start date (links to DIM_VAGUE for temporal visualizations)
    // -----------------------------
    AvecDate = Table.AddColumn(AvecVague, "Date_Debut_Vague", each #date(2020, 2, 23), type date)
in
    AvecDate
