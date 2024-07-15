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
        codeunit "NCT ETaxFunc" = X,
        page "NCT Etax Log Entry" = X,
        report "NCT ETax Sales Credit Memo" = X,
        report "Etax Select Header Receipt" = X,
        report "Etax Select Header Invoice" = X,
        report "NCT ETax Sales Invoice" = X,
        report "NCT ETax Sales Receipt" = X;
}
