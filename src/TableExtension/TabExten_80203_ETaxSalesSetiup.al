/// <summary>
/// TableExtension NCT ETax Sales Setiup (ID 80203) extends Record Sales Receivables Setup.
/// </summary>
tableextension 80203 "NCT ETax Sales Setiup" extends "Sales & Receivables Setup"
{
    fields
    {
        field(80200; "NCT Etax Seller Tax ID"; text[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Seller Tax ID';
        }
        field(80201; "NCT Etax Seller Branch ID"; text[10])
        {
            Caption = 'Seller Branch ID';
            DataClassification = CustomerContent;
        }
        field(80202; "NCT Etax API Key"; Text[2047])
        {
            Caption = 'API Key';
            DataClassification = CustomerContent;
        }
        field(80203; "NCT Etax User Code"; text[100])
        {
            Caption = 'User Code';
            DataClassification = CustomerContent;
        }
        field(80204; "NCT Etax Access Key"; text[10])
        {
            Caption = 'Access Key';
            DataClassification = CustomerContent;
        }
        field(80205; "NCT Etax Service URL"; text[250])
        {
            Caption = 'Service URL';
            DataClassification = CustomerContent;
        }
        field(80206; "NCT Etax Service Code"; Enum "NCT Etax Service Type")
        {
            Caption = 'Service Code';
            DataClassification = CustomerContent;
        }
        field(80207; "NCT Etax Download PDF File"; Boolean)
        {
            Caption = 'Download PDF File';
            DataClassification = CustomerContent;
        }
        field(80208; "NCT Etax Download Text File"; Boolean)
        {
            Caption = 'Download Text File';
            DataClassification = CustomerContent;
        }
    }
}
