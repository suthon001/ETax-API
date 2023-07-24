/// <summary>
/// TableExtension NCT ETax Sales Setiup (ID 80203) extends Record Sales Receivables Setup.
/// </summary>
tableextension 80203 "NCT ETax Sales Setiup" extends "Sales & Receivables Setup"
{
    fields
    {
        field(80200; "NCT Etax Seller Tax ID"; text[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Seller Tax ID';
        }
        field(80201; "NCT Etax Seller Branch ID"; text[10])
        {
            Caption = 'Seller Branch ID';
            DataClassification = ToBeClassified;
        }
        field(80202; "NCT Etax API Key"; Blob)
        {
            Caption = 'API Key';
            DataClassification = ToBeClassified;
        }
        field(80203; "NCT Etax User Code"; text[100])
        {
            Caption = 'User Code';
            DataClassification = ToBeClassified;
        }
        field(80204; "NCT Etax Access Key"; text[10])
        {
            Caption = 'Access Key';
            DataClassification = ToBeClassified;
        }
        field(80205; "NCT Etax Service URL"; text[250])
        {
            Caption = 'Service URL';
            DataClassification = ToBeClassified;
        }
        field(80206; "NCT Etax Service Code"; Enum "NCT Etax Service Type")
        {
            Caption = 'Service Code';
            DataClassification = ToBeClassified;
        }
    }
    /// <summary>
    /// GetBlobData_APIKey.
    /// </summary>
    /// <returns>Return value of type Text.</returns>
    procedure GetBlobData_APIKey(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin

        CalcFields("NCT Etax API Key");
        "NCT Etax API Key".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;
    /// <summary>
    /// SetBlobData_APIKey.
    /// </summary>
    /// <param name="ContentData">Text.</param>
    procedure SetBlobData_APIKey(ContentData: Text)
    var
        OutStrm: OutStream;
    begin
        Clear("NCT Etax API Key");
        "NCT Etax API Key".CreateOutStream(OutStrm, TextEncoding::UTF8);
        OutStrm.WriteText(ContentData);
        Modify();
    end;
}
