/// <summary>
/// TableExtension DSVCCompanyInformation (ID 70204) extends Record Company Information.
/// </summary>
tableextension 70204 "DSVCCompanyInformation" extends "Company Information"
{
    fields
    {
        field(70200; "DSVC Etax Branch Code"; Code[12])
        {
            Caption = 'E-tax Branch Code';
            DataClassification = CustomerContent;
        }
    }
}