/// <summary>
/// TableExtension NCT Etax No. Series (ID 80202) extends Record No. Series.
/// </summary>
tableextension 80202 "NCT Etax No. Series" extends "No. Series"
{
    fields
    {
        field(80200; "NCT Etax Type Code"; enum "NCT Etax Type")
        {
            Caption = 'E-tax Type Code';
            DataClassification = CustomerContent;

        }
        field(80201; "NCT Etax Type Eng Code"; enum "NCT Etax Type Eng")
        {
            Caption = 'E-tax Type Eng Code';
            DataClassification = CustomerContent;
            Editable = false;

        }
    }

}
