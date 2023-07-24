/// <summary>
/// Page NCT Etax Log Entry (ID 80200).
/// </summary>
page 80200 "NCT Etax Log Entry"
{
    Caption = 'E-Tax Log Entry';
    PageType = List;
    SourceTable = "NCT Etax Log";
    UsageCategory = Lists;
    ApplicationArea = all;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the value of the Entry No. field.';
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the value of the Status field.';
                    ApplicationArea = All;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ToolTip = 'Specifies the value of the Document Type field.';
                    ApplicationArea = All;
                }
                field("Document No."; Rec."Document No.")
                {
                    ToolTip = 'Specifies the value of the Document No. field.';
                    ApplicationArea = All;
                }
                field("Etax Type"; Rec."Etax Type")
                {
                    ToolTip = 'Specifies the value of the Etax Type field.';
                    ApplicationArea = All;
                }
                field("Create By"; Rec."Create By")
                {
                    ToolTip = 'Specifies the value of the Create By field.';
                    ApplicationArea = All;
                }
                field("Create DateTime"; Rec."Create DateTime")
                {
                    ToolTip = 'Specifies the value of the Create DateTime field.';
                    ApplicationArea = All;
                }

                field("Last Pdf File"; Rec."Last Pdf File")
                {
                    ToolTip = 'Specifies the value of the Last Pdf File field.';
                    ApplicationArea = All;
                }
                field("Last Text File"; Rec."Last Text File")
                {
                    ToolTip = 'Specifies the value of the Last Text File field.';
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ExportTextFile)
            {
                Caption = 'Export Text File';
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = ExportAttachment;
                ToolTip = 'Executes the Export Text File action.';
                trigger OnAction()
                var
                    TenantMedia: Record "Tenant Media";
                    TempBlob: Codeunit "Temp Blob";
                    DocumentInStream: InStream;
                    DocumentOutStream: OutStream;
                    FileMgt: Codeunit "File Management";
                begin
                    Clear(TempBlob);
                    TenantMedia.GET(rec."Last Text File".Item(1));
                    TenantMedia.CalcFields(Content);
                    if TenantMedia.Content.HasValue then begin
                        TenantMedia.Content.CreateInStream(DocumentInStream);
                        TempBlob.CreateOutStream(DocumentOutStream);
                        CopyStream(DocumentOutStream, DocumentInStream);
                        FileMgt.BLOBExport(TempBlob, rec."File Name" + '.txt', true);
                    end;
                end;
            }
            action(ExportPDFFile)
            {
                Caption = 'Export PDF File';
                ApplicationArea = all;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = ExportAttachment;
                ToolTip = 'Executes the Export PDF File action.';
                trigger OnAction()
                var
                    TenantMedia: Record "Tenant Media";
                    TempBlob: Codeunit "Temp Blob";
                    DocumentInStream: InStream;
                    DocumentOutStream: OutStream;
                    FileMgt: Codeunit "File Management";
                begin
                    Clear(TempBlob);
                    TenantMedia.GET(rec."Last PDF File".Item(1));
                    TenantMedia.CalcFields(Content);
                    if TenantMedia.Content.HasValue then begin
                        TenantMedia.Content.CreateInStream(DocumentInStream);
                        TempBlob.CreateOutStream(DocumentOutStream);
                        CopyStream(DocumentOutStream, DocumentInStream);
                        FileMgt.BLOBExport(TempBlob, rec."File Name" + '.pdf', true);
                    end;
                end;
            }
        }
    }
}
