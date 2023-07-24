/// <summary>
/// PageExtension NCT Etax No. Series (ID 80200) extends Record No. Series.
/// </summary>
pageextension 80200 "NCT Etax No. Series" extends "No. Series"
{
    layout
    {
        addafter(Description)
        {
            field("NCT Etax Type Code"; rec."NCT Etax Type Code")
            {
                ApplicationArea = all;
                ToolTip = 'Specifies the value of the NCT Etax Type Code field.';
            }
        }
    }
}
