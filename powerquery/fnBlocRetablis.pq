// ============================================================================
// fnBlocRetablis — Power Query M function
// ----------------------------------------------------------------------------
// Restructures the "recoveries block" from an INSPQ wave file into a clean
// long-format table. This is a SPECIAL CASE because the recoveries block
// has only 3 columns (no percentages, no rates, no unknown-sex category).
//
// PARAMETERS
//   src : table — the raw wave table (already loaded, header dropped)
//
// EXPECTED INPUT STRUCTURE
//   Column1  : age group
//   Column11 : female recovery count
//   Column12 : male recovery count
//   Column13 : total recovery count (excluded — recomputed by DAX)
//
// OUTPUT SCHEMA (matches fnBloc output for clean stacking)
//   Groupe_Age, Nombre, Pourcentage, Taux_100000, REF_SEXE, Indicateur, Code_Age
//   (Pourcentage and Taux_100000 are filled with null)
//
// USAGE
//   fnBlocRetablis(PL_v1_brut)
// ============================================================================

let
    fnBlocRetablis = (src as table) as table =>
    let
        // Helper : builds a Power Query column name from its position number
        col = (n as number) as text => "Column" & Text.From(n),
        
        // -----------------------------
        // FEMALE sub-table (count only, no percentage / no rate)
        // -----------------------------
        F = Table.RenameColumns(
            Table.SelectColumns(src, {"Column1", col(11)}),
            {{"Column1", "Groupe_Age"}, {col(11), "Nombre"}}
        ),
        F_pct  = Table.AddColumn(F, "Pourcentage", each null),
        F_taux = Table.AddColumn(F_pct, "Taux_100000", each null),
        F_sexe = Table.AddColumn(F_taux, "REF_SEXE", each "F", type text),
        
        // -----------------------------
        // MALE sub-table (count only)
        // -----------------------------
        H = Table.RenameColumns(
            Table.SelectColumns(src, {"Column1", col(12)}),
            {{"Column1", "Groupe_Age"}, {col(12), "Nombre"}}
        ),
        H_pct  = Table.AddColumn(H, "Pourcentage", each null),
        H_taux = Table.AddColumn(H_pct, "Taux_100000", each null),
        H_sexe = Table.AddColumn(H_taux, "REF_SEXE", each "H", type text),
        
        // -----------------------------
        // Stack F + H and tag indicator (no UNK for recoveries)
        // -----------------------------
        Empile = Table.Combine({F_sexe, H_sexe}),
        AvecIndicateur = Table.AddColumn(Empile, "Indicateur", each "Rétablissements", type text),
        
        // -----------------------------
        // Filter : keep only valid age groups
        // -----------------------------
        AgesValides = {
            "0-9 ans", "10-19 ans", "20-29 ans", "30-39 ans", "40-49 ans",
            "50-59 ans", "60-69 ans", "70-79 ans", "80-89 ans", "90 ans et plus",
            "Inconnu"
        },
        Filtre = Table.SelectRows(AvecIndicateur, each List.Contains(AgesValides, [Groupe_Age])),
        
        // -----------------------------
        // Add sortable age code
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
    fnBlocRetablis
