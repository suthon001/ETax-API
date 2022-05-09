/// <summary>
/// PageExtension DSVCCompnayInformation (ID 70203) extends Record Company Information.
/// </summary>
pageextension 70203 "DSVCCompnayInformation" extends "Company Information"
{
    layout
    {
        addlast(General)
        {
            field("DSVC Etax Branch Code"; rec."DSVC Etax Branch Code")
            {
                ApplicationArea = all;
                ToolTip = 'Branch Code for E-Tax';
            }
        }
    }
}