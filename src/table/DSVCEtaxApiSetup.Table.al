/// <summary>
/// Table DSVCEtaxApi Setup (ID 70200).
/// </summary>
table 70200 "DSVCEtaxApi Setup"
{
    LookupPageId = DSVCEtaxSetups;
    DrillDownPageId = DSVCEtaxSetups;
    fields
    {
        field(1; "DSVC Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
        }
        field(2; "DSVC API Name"; Text[20])
        {
            Caption = 'API Name';
            DataClassification = CustomerContent;
        }
        field(3; "DSVC API Value"; Text[2024])
        {
            Caption = 'API Value';
            DataClassification = CustomerContent;
        }
        field(4; "DSVC Remark"; Text[1024])
        {
            Caption = 'Remark';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK1; "DSVC Entry No.")
        {
            Clustered = true;
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; "DSVC API Name", "DSVC API Value") { }
    }
}