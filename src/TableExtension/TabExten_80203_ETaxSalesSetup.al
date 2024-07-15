/// <summary>
/// TableExtension NCT ETax Sales Setup (ID 80203) extends Record Sales Receivables Setup.
/// </summary>
tableextension 80203 "NCT ETax Sales Setup" extends "Sales & Receivables Setup"
{
    fields
    {
        field(80200; "NCT Etax Seller Tax ID"; text[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Seller Tax ID';
            trigger OnValidate()
            begin
                TestField("Etax Active", false);
            end;
        }
        field(80201; "NCT Etax Seller Branch ID"; text[10])
        {
            Caption = 'Seller Branch ID';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                TestField("Etax Active", false);
            end;
        }
        field(80202; "NCT Etax API Key"; Text[2047])
        {
            Caption = 'API Key';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                TestField("Etax Active", false);
            end;
        }
        field(80203; "NCT Etax Service URL"; text[250])
        {
            Caption = 'Service URL';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                TestField("Etax Active", false);
            end;
        }
        field(80204; "NCT Etax Service Code"; Enum "NCT Etax Service Type")
        {
            Caption = 'Service Code';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                TestField("Etax Active", false);
            end;
        }
        field(80205; "NCT Etax Download PDF File"; Boolean)
        {
            Caption = 'Download PDF File';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                TestField("Etax Active", false);
            end;
        }
        field(80206; "NCT Etax Download Text File"; Boolean)
        {
            Caption = 'Download Text File';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                TestField("Etax Active", false);
            end;
        }
        field(80207; "NCT Etax Download XML File"; Boolean)
        {
            Caption = 'Download XML File';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                TestField("Etax Active", false);
            end;
        }
        field(80208; "Etax Get check status URL"; text[250])
        {
            Caption = 'Get check status URL';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                TestField("Etax Active", false);
            end;
        }
        field(80209; "Etax Active"; Boolean)
        {
            Caption = 'Active';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                if rec."Etax Active" then begin
                    rec.TestField("NCT Etax API Key");
                    rec.TestField("NCT Etax Seller Branch ID");
                    rec.TestField("NCT Etax Seller Tax ID");
                    rec.TestField("NCT Etax Service URL");
                end;
            end;
        }
    }
}
