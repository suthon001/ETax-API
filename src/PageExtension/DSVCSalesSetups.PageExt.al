/// <summary>
/// PageExtension DSVCSales Setups (ID 70201) extends Record Sales Receivables Setup.
/// </summary>
pageextension 70201 "DSVCSales Setups" extends "Sales & Receivables Setup"
{
    layout
    {
        addafter(General)
        {
            group(DSVCEtaxSetup)
            {
                Caption = 'E-Tax Setup';
                field("DSVC URL"; rec."DSVC URL")
                {
                    ApplicationArea = all;
                    ToolTip = 'URL Address for api';
                }
            }
        }
    }
}