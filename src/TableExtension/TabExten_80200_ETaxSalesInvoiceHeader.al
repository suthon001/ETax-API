/// <summary>
/// TableExtension NCT ETax Sales Invoice Header (ID 80200) extends Record Sales Invoice Header.
/// </summary>
tableextension 80200 "NCT ETax Sales Invoice Header" extends "Sales Invoice Header"
{
    fields
    {
        field(80245; "NCT Etax Last File Name"; Text[250])
        {
            Editable = false;
            Caption = 'E-tax Last File Name';
            DataClassification = CustomerContent;
        }
        field(80246; "NCT Etax No. of Send"; Integer)
        {
            Editable = false;
            Caption = 'E-tax No. of Send';
            DataClassification = CustomerContent;
        }
        field(80247; "NCT Etax Status"; Enum "NCT Etax Status")
        {
            Editable = false;
            Caption = 'E-tax Status';
            DataClassification = CustomerContent;
        }
        field(80248; "NCT Etax Send to E-Tax"; Boolean)
        {
            Caption = 'E-tax Send to E-Tax';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(80249; "NCT Etax Send DateTime"; DateTime)
        {
            Caption = 'E-tax Send DateTime';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(80250; "NCT Etax Send By"; Code[50])
        {
            Caption = 'E-tax Send By';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
