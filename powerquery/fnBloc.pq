// ============================================================================
// fnBloc — Power Query M function
// ----------------------------------------------------------------------------
// Restructures a "rich indicator block" (9 columns) from an INSPQ wave file
// into a clean long-format table with sex as a proper variable.
//
// PARAMETERS
//   src         : table   — the raw wave table (already loaded, header dropped)
//   p           : number  — position of the female-count column (1-indexed)
//   indicateur  : text    — name of the indicator (e.g. "Cas", "Décès")
//
// EXPECTED INPUT STRUCTURE (relative to p)
//   Column1 : age group
//   p       : female count
//   p+1     : female percentage
//   p+2     : female rate per 100,000
//   p+3     : male count
//   p+4     : male percentage
//   p+5     : male rate per 100,000
//   p+6     : unknown-sex count
//   p+7     : total (excluded — recomputed by DAX)
//   p+8     : total rate (excluded — recomputed by DAX)
//
// OUTPUT SCHEMA
//   Groupe_Age, Nombre, Pourcentage, Taux_100000, REF_SEXE, Indicateur, Code_Age
//
// USAGE
//   fnBloc(PL_v1_brut, 2,  "Cas")
//   fnBloc(PL_v1_brut, 14, "Décès")
//   fnBloc(PL_v1_brut, 23, "Hospitalisation totale")
//   fnBloc(PL_v1_brut, 32, "Hospitalisation soins intensifs")
//   fnBloc(PL_v1_brut, 41, "Hospitalisation hors soins intensifs")
// ============================================================================

let
    fnBloc = (src as table, p as number, indicateur as text) as table =>
    let
        // Column offsets relative to the female-count position
        decalage_H   = 3,    // Male count is 3 columns after female count
        decalage_UNK = 6,    // Unknown-sex count is 6 columns after female count
        
        // Helper : builds a Power Query column name from its position number
        // (Power Query default column names are "Column1", "Column2", ...)
        col = (n as number) as text => "Column" & Text.From(n),
        
        // -----------------------------
        // FEMALE sub-table
        // -----------------------------
        F = Table.RenameColumns(
            Table.SelectColumns(src, {"Column1", col(p), col(p+1), col(p+2)}),
            {
                {"Column1",  "Groupe_Age"},
                {col(p),     "Nombre"},
                {col(p+1),   "Pourcentage"},
                {col(p+2),   "Taux_100000"}
            }
        ),
        F_sexe = Table.AddColumn(F, "REF_SEXE", each "F", type text),
        
        // -----------------------------
        // MALE sub-table
        // -----------------------------
        H = Table.RenameColumns(
            Table.SelectColumns(src, {"Column1", col(p+decalage_H), col(p+decalage_H+1), col(p+decalage_H+2)}),
            {
                {"Column1",              "Groupe_Age"},
                {col(p+decalage_H),      "Nombre"},
                {col(p+decalage_H+1),    "Pourcentage"},
                {col(p+decalage_H+2),    "Taux_100000"}
            }
        ),
        H_sexe = Table.AddColumn(H, "REF_SEXE", each "H", type text),
        
        // -----------------------------
        // UNKNOWN-SEX sub-table (count only, no percentage / no rate)
        // -----------------------------
        U = Table.RenameColumns(
            Table.SelectColumns(src, {"Column1", col(p+decalage_UNK)}),
            {
                {"Column1",            "Groupe_Age"},
                {col(p+decalage_UNK),  "Nombre"}
            }
        ),
        U_pct  = Table.AddColumn(U, "Pourcentage", each null),
        U_taux = Table.AddColumn(U_pct, "Taux_100000", each null),
        U_sexe = Table.AddColumn(U_taux, "REF_SEXE", each "UNK", type text),
        
        // -----------------------------
        // Stack F + H + UNK and tag with indicator name
        // -----------------------------
        Empile = Table.Combine({F_sexe, H_sexe, U_sexe}),
        AvecIndicateur = Table.AddColumn(Empile, "Indicateur", each indicateur, type text),
        
        // -----------------------------
        // Filter : keep only valid age groups (excludes totals, notes, blanks)
        // -----------------------------
        AgesValides = {
            "0-9 ans", "10-19 ans", "20-29 ans", "30-39 ans", "40-49 ans",
            "50-59 ans", "60-69 ans", "70-79 ans", "80-89 ans", "90 ans et plus",
            "Inconnu"
        },
        Filtre = Table.SelectRows(AvecIndicateur, each List.Contains(AgesValides, [Groupe_Age])),
        
        // -----------------------------
        // Add sortable age code (for DIM_GROUPE_AGE relationship)
        // -----------------------------
        AjusterFormatAge = Table.AddColumn(Filtre, "Code_Age", each 
            if [Groupe_Age] = "0-9 ans"        then "AGE_00_09"
            else if [Groupe_Age] = "10-19 ans" then "AGE_10_19"
            else if [Groupe_Age] = "20-29 ans" then "AGE_20_29"
            else if [Groupe_Age] = "30-39 ans" then "AGE_30_39"
            else if [Groupe_Age] = "40-49 ans" then "AGE_40_49"
            else if [Groupe_Age] = "50-59 ans" then "AGE_50_59"
            else if [Groupe_Age] = "60-69 ans" then "AGE_60_69"
            else if [Groupe_Age] = "70-79 ans" then "AGE_70_79"
            else if [Groupe_Age] = "80-89 ans" then "AGE_80_89"
            else if [Groupe_Age] = "90 ans et plus" then "AGE_90_plus"
            else if [Groupe_Age] = "Inconnu"   then "AGE_inconnu"
            else "AGE_autre",
            type text
        )
    in
        AjusterFormatAge
in
    fnBloc
