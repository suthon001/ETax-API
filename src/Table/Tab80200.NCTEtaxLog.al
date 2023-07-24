/// <summary>
/// Table NCT Etax Log (ID 80200).
/// </summary>
table 80200 "NCT Etax Log"
{
    Caption = 'Etax Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Sales Invoice,Sales Credit Memo,Sales Receipt';
            OptionMembers = "Sales Invoice","Sales Credit Memo","Sales Receipt";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "File Name"; Text[250])
        {
            Caption = 'File Name';
        }
        field(5; "Create By"; Code[50])
        {
            Caption = 'Create By';
        }
        field(6; "Create DateTime"; DateTime)
        {
            Caption = 'Create DateTime';
        }
        field(7; Status; Enum "NCT Etax Status")
        {
            Caption = 'Status';
        }
        field(8; "Last Pdf File"; MediaSet)
        {
            Caption = 'Last Pdf File';
        }
        field(9; "Last Text File"; MediaSet)
        {
            Caption = 'Last Text File';
        }
        field(10; "Etax Type"; Text[250])
        {
            Caption = 'Etax Type';
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
