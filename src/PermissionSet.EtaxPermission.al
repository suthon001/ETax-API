/// <summary>
/// Unknown NCT Etax Permission (ID 80200).
/// </summary>
permissionset 80200 "NCT Etax Permission"
{
    Assignable = true;
    Caption = 'Etax Permission', MaxLength = 30;
    Permissions =
        table "NCT Etax Log" = X,
        tabledata "NCT Etax Log" = RMID,
        page "NCT Etax Log Entry" = X,
        codeunit "NCT ETaxFunc" = X;
}
