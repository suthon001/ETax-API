/// <summary>
/// Table NCT Etax Log (ID 80200).
/// </summary>
table 80200 "NCT Etax Log"
{
    Caption = 'Etax Log';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Etax Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Etax Type"; Text[250])
        {
            Caption = 'Etax Type';
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
        field(10; "File Name"; text[100])
        {
            Caption = 'File Name';
        }
        field(11; "NCT Error Msg."; Text[2047])
        {
            Editable = false;
            Caption = 'Error Msg.';
            DataClassification = CustomerContent;
        }
        field(12; "Last XML File"; MediaSet)
        {
            Caption = 'Last XML File';
        }
        field(13; "Header Report"; text[100])
        {
            Caption = 'Header Report';
            Editable = false;
        }
        field(14; "Transaction Code"; text[100])
        {
            Caption = 'Transaction Code';
            Editable = false;
        }
        field(15; "Etax Type Code"; code[20])
        {
            Caption = 'Etax Type Code';
        }
    }
    keys
    {
        key(PK; "Document Type", "Entry No.")
        {
            Clustered = true;
        }
    }
    /// <summary>
    /// GetLastEntry.
    /// </summary>
    /// <returns>Return value of type Integer.</returns>
    procedure GetLastEntry(): Integer
    var
        LogEtax: Record "NCT Etax Log";
    begin
        LogEtax.Reset();
        LogEtax.SetCurrentKey("Document Type", "Entry No.");
        LogEtax.SetRange("Document Type", rec."Document Type");
        if LogEtax.FindLast() then
            exit(LogEtax."Entry No." + 1);
        exit(1);
    end;
}
