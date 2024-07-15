/// <summary>
/// Enum Etax Document Type (ID 80205).
/// </summary>
enum 80205 "Etax Document Type"
{
    Extensible = true;

    value(0; "Sales Invoice")
    {
        Caption = 'Sales Invoice';
    }
    value(1; "Sales Credit Memo")
    {
        Caption = 'Sales Credit Memo';
    }
    value(2; "Sales Receipt")
    {
        Caption = 'Sales Receipt';
    }
}
