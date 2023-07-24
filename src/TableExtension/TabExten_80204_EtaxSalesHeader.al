/// <summary>
/// TableExtension NCT Etax Sales Header (ID 80204) extends Record Sales Header.
/// </summary>
tableextension 80204 "NCT Etax Sales Header" extends "Sales Header"
{
    fields
    {
        field(80200; "NCT Etax Purpose"; Enum "NCT Etax Purpose")
        {
            Caption = 'E-Tax Purpose';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if xRec."NCT Etax Purpose" <> Rec."NCT Etax Purpose" then
                    if rec."NCT Etax Purpose" in [rec."NCT Etax Purpose"::CDNG99, rec."NCT Etax Purpose"::CDNS99] then
                        rec."NCT Etax Purpose Remark" := ''
                    else
                        rec."NCT Etax Purpose Remark" := format(Rec."NCT Etax Purpose");

            end;
        }
        field(80201; "NCT Etax Purpose Remark"; text[250])
        {
            Caption = 'E-Tax Purpose Remark';
            DataClassification = CustomerContent;
        }
    }
}
