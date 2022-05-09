/// <summary>
/// TableExtension DSVCSalesSetup (ID 70200) extends Record Sales Receivables Setup.
/// </summary>
tableextension 70200 "DSVCSalesSetup" extends "Sales & Receivables Setup"
{
    fields
    {
        field(70200; "DSVC URL"; Text[1024])
        {
            Caption = 'E-Tax URL';
            DataClassification = CustomerContent;
        }
    }
}