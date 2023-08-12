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
        report "NCT ETax Sales Credit Memo" = X,
        report "NCT ETax Sales Invoice" = X,
        report "NCT ETax Sales Receipt" = X,
        codeunit "NCT ETaxFunc" = X;
}
