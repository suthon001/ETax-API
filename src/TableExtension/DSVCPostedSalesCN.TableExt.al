/// <summary>
/// TableExtension DSVCPostedSales CN (ID 70203) extends Record Sales Cr.Memo Header.
/// </summary>
tableextension 70203 "DSVCPostedSales CN" extends "Sales Cr.Memo Header"
{
    fields
    {
        field(70200; "DSVC Generate E-Tax"; Boolean)
        {
            Caption = 'Generate E-Tax';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(70201; "DSVC Generate E-Tax by"; Code[30])
        {
            Caption = 'Generate E-Tax By';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(70202; "DSVC Generate E-Tax DateTime"; DateTime)
        {
            Caption = 'Generate E-Tax DateTime';
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(70203; "DSVC E-Tax FileName"; text[1024])
        {
            Caption = 'E-Tax FileName';
            Editable = false;
            DataClassification = SystemMetadata;
        }
    }
}