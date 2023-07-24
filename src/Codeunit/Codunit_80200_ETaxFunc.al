/// <summary>
/// Codeunit NCT ETaxFunc (ID 80200).
/// </summary>
codeunit 80200 "NCT ETaxFunc"
{
    Permissions = tabledata "Sales Invoice Header" = rimd, tabledata "Sales Cr.Memo Header" = rimd, tabledata "NCT Billing Receipt Header" = rimd;
    /// <summary>
    /// ETaxSalesInvoice.
    /// </summary>
    /// <param name="pSalesInvHeader">Record "Sales Invoice Header".</param>
    procedure ETaxSalesInvoice(pSalesInvHeader: Record "Sales Invoice Header")
    var
        Cust: Record Customer;
        SalesInvoiceLine: Record "Sales Invoice Line";
        NoSeries: Record "No. Series";
        Itemcategory: Record "Item Category";
        PaymentTerms: Record "Payment Terms";
        ltItem: Record Item;
        WHTBus: Record "NCT WHT Business Posting Group";
        ltTempblob: Codeunit "Temp Blob";
        ltOutStream: OutStream;
        ltInStream: InStream;
        ltFilenameLbl: Label 'SalesInvoice_%1_%2_%3';
        ltFileName, ToFileName : Text;
        DataText, ltVatBranch, ltCustVatBranch, EtaxData, NewLine : Text;
        CurrencyCode: Code[10];
        TotalSalesInvoiceLine, LineNo : Integer;
        VatPer, TotalLineDisAmt : Decimal;
        TotalAmt: array[100] of Decimal;
        CR: Char;
        LF: Char;
    begin
        //CheckService();

        Clear(DataText);
        CLEAR(TotalAmt);
        CLEAR(EtaxData);
        LineNo := 0;
        CR := 13;
        LF := 10;
        NewLine := '' + CR + LF;
        Clear(ltTempblob);
        pSalesInvHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        if pSalesInvHeader."Amount Including VAT" <> 0 then begin
            NoSeries.GET(pSalesInvHeader."No. Series");
            NoSeries.TestField("NCT Etax Type Code");
            CompanyInfo.GET();
            CompanyInfo.TestField("VAT Registration No.");
            Cust.GET(pSalesInvHeader."Sell-to Customer No.");
            if not PaymentTerms.GET(pSalesInvHeader."Payment Terms Code") then
                PaymentTerms.Init();
            ltFileName := StrSubstNo(ltFilenameLbl, CompanyInfo."VAT Registration No.", pSalesInvHeader."No.", pSalesInvHeader."NCT Etax No. of Send" + 1) + '.txt';
            ToFileName := StrSubstNo(ltFilenameLbl, CompanyInfo."VAT Registration No.", pSalesInvHeader."No.", pSalesInvHeader."NCT Etax No. of Send" + 1);
            DataText := SetDataEtax('C', true);
            DataText += SetDataEtax(DelChr(CompanyInfo."VAT Registration No.", '=', '-'), true);
            VatBusSetup.get(pSalesInvHeader."VAT Bus. Posting Group");
            if not WHTBus.GET(pSalesInvHeader."NCT WHT Business Posting Group") then
                WHTBus.Init();
            if VatBusSetup."NCT Head Office" then
                ltVatBranch := '00000'
            else
                ltVatBranch := VatBusSetup."NCT VAT Branch Code";
            if ltVatBranch = '' then
                ltVatBranch := '00000';

            DataText += SetDataEtax(ltVatBranch, true);
            DataText += SetDataEtax(ltFileName, false);
            EtaxData := DataText + NewLine;

            DataText := SetDataEtax('H', true); //1
            DataText += SetDataEtax(GetEnumValueName(NoSeries."NCT Etax Type Code"), true); //2
            DataText += SetDataEtax(format(NoSeries."NCT Etax Type Code"), true); // 3
            DataText += SetDataEtax(pSalesInvHeader."No.", true); //4
            DataText += SetDataEtax(format(pSalesInvHeader."Document Date", 0, '<Year4>-<Month,2>-<Day,2>') + 'T00:00:00', true); //5
            DataText += SetDataEtax('', true);//6
            DataText += SetDataEtax('', true);//7
            DataText += SetDataEtax('', true);//8
            DataText += SetDataEtax('', true);//9
            DataText += SetDataEtax('', true);//10
            DataText += SetDataEtax(pSalesInvHeader."External Document No.", true);//11
            DataText += SetDataEtax('', true);//12
            DataText += SetDataEtax('', true);//13
            DataText += SetDataEtax('', true);//14
            DataText += SetDataEtax('', true);//15
            DataText += SetDataEtax('', true);//16
            DataText += SetDataEtax('', true);//17
            DataText += SetDataEtax('', true);//18
            DataText += SetDataEtax('', true);//19
            DataText += SetDataEtax('', true);//20
            DataText += SetDataEtax('', true);//21
            DataText += SetDataEtax('', true);//22
            DataText += SetDataEtax(ltVatBranch, true);//23
            DataText += SetDataEtax('', true);//24
            DataText += SetDataEtax('', true);//25
            DataText += SetDataEtax('', true);//26
            if Cust."E-Mail" <> '' then
                DataText += SetDataEtax('Y', false) //27
            else
                DataText += SetDataEtax('N', false);
            EtaxData := EtaxData + DataText + NewLine;

            if not Cust.GET(pSalesInvHeader."Bill-to Customer No.") then
                Cust.Init();

            if pSalesInvHeader."NCT Head Office" then
                ltCustVatBranch := '00000'
            else
                ltCustVatBranch := Cust."NCT VAT Branch Code";
            if ltCustVatBranch = '' then
                ltCustVatBranch := '00000';

            DataText := SetDataEtax('B', true); //1
            DataText += SetDataEtax(pSalesInvHeader."Bill-to Customer No.", true); //2
            DataText += SetDataEtax(pSalesInvHeader."Bill-to Name" + ' ' + pSalesInvHeader."Bill-to Name 2", true); //3
            if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::" " then
                DataText += SetDataEtax('', true);
            if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::"ภ.ง.ด.3" then
                DataText += SetDataEtax('NIDN', true);
            if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::"ภ.ง.ด.53" then
                DataText += SetDataEtax('TXID', true);
            if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::"ภ.ง.ด.54" then
                DataText += SetDataEtax('CCPT', true);

            DataText += SetDataEtax(DelChr(pSalesInvHeader."VAT Registration No.", '=', '-'), true); //5
            if WHTBus."WHT Certificate Option" = WHTBus."WHT Certificate Option"::"ภ.ง.ด.53" then
                DataText += SetDataEtax(ltCustVatBranch, true)
            else
                DataText += SetDataEtax('', true);
            DataText += SetDataEtax(pSalesInvHeader."Bill-to Contact", true);
            DataText += SetDataEtax('', true);
            Cust.get(pSalesInvHeader."Sell-to Customer No.");
            DataText += SetDataEtax(Cust."E-Mail", true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax(pSalesInvHeader."bill-to Post Code", true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax(pSalesInvHeader."bill-to Address" + ' ' + pSalesInvHeader."bill-to Address 2", true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax(pSalesInvHeader."bill-to Post Code", true);
            DataText += SetDataEtax(pSalesInvHeader."bill-to City", true);
            DataText += SetDataEtax(pSalesInvHeader."bill-to Country/Region Code", false);
            EtaxData := EtaxData + DataText + NewLine;

            if pSalesInvHeader."Currency Code" <> '' then
                CurrencyCode := CopyStr(CurrencyCode, 1, 3)
            else
                CurrencyCode := 'THB';
            SalesInvoiceLine.reset();
            SalesInvoiceLine.SetRange("Document No.", pSalesInvHeader."No.");
            SalesInvoiceLine.SetFilter("No.", '<>%1', '');
            TotalSalesInvoiceLine := SalesInvoiceLine.count();
            if SalesInvoiceLine.FindSet() then
                repeat
                    LineNo += 1;
                    if not ltItem.GET(SalesInvoiceLine."No.") then
                        ltItem.init();
                    if not Itemcategory.GET(ltItem."Item Category Code") then
                        Itemcategory.Init();



                    DataText := SetDataEtax('L', true);
                    DataText += SetDataEtax(format(LineNo), true);
                    DataText += SetDataEtax(SalesInvoiceLine."No.", true);
                    DataText += SetDataEtax(SalesInvoiceLine.Description + ' ' + SalesInvoiceLine."Description 2", true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(ltItem."Item Category Code", true);
                    DataText += SetDataEtax(Itemcategory.Description, true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(format(SalesInvoiceLine."Unit Price", 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(format(SalesInvoiceLine."Line Discount Amount", 0, '<Precision,2:2><Standard Format,0>'), true);
                    if SalesInvoiceLine."Line Discount Amount" <> 0 then
                        DataText += SetDataEtax(CurrencyCode, true)
                    else
                        DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(format(SalesInvoiceLine.Quantity), true);
                    DataText += SetDataEtax(SalesInvoiceLine."Unit of Measure Code", true);
                    DataText += SetDataEtax(format(SalesInvoiceLine."Qty. per Unit of Measure"), true);
                    DataText += SetDataEtax(format(SalesInvoiceLine."VAT %"), true);
                    DataText += SetDataEtax(format(SalesInvoiceLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(format(SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax('', true);
                    DataText += SetDataEtax(format(SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(format(SalesInvoiceLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
                    DataText += SetDataEtax(CurrencyCode, true);
                    DataText += SetDataEtax(format(SalesInvoiceLine."Amount Including VAT", 0, '<Precision,2:2><Standard Format,0>'), true);
                    if TotalSalesInvoiceLine <> LineNo then
                        DataText += SetDataEtax(CurrencyCode, true)
                    else
                        DataText += SetDataEtax(CurrencyCode, false);
                    EtaxData := EtaxData + DataText + NewLine;
                until SalesInvoiceLine.next() = 0;
            SalesInvoiceLine.reset();
            SalesInvoiceLine.SetRange("Document No.", pSalesInvHeader."No.");
            SalesInvoiceLine.SetFilter("VAT %", '<>%1', 0);
            if SalesInvoiceLine.FindFirst() then
                VatPer := SalesInvoiceLine."VAT %";

            TotalLineDisAmt := pSalesInvHeader."Invoice Discount Amount";

            SalesInvoiceLine.Reset();
            SalesInvoiceLine.SetRange("Document No.", pSalesInvHeader."No.");
            SalesInvoiceLine.Setfilter("Line Amount", '<%1', 0);
            if SalesInvoiceLine.FindSet() then begin
                SalesInvoiceLine.CalcSums("Line Amount");
                TotalLineDisAmt := TotalLineDisAmt + ABS(SalesInvoiceLine."Line Amount");

            end;
            NCTLCLFunction.PostedSalesInvoiceStatistics(pSalesInvHeader."No.", TotalAmt, VATText);

            DataText := SetDataEtax('F', true);
            DataText += SetDataEtax(format(TotalSalesInvoiceLine), true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax(CurrencyCode, true);
            DataText += SetDataEtax('VAT', true);
            DataText += SetDataEtax(format(VatPer, 0, '<Precision,2:2><Standard Format,0>'), true);
            DataText += SetDataEtax(format(TotalAmt[1], 0, '<Precision,2:2><Standard Format,0>'), true);
            DataText += SetDataEtax(CurrencyCode, true);
            DataText += SetDataEtax(format(TotalAmt[4], 0, '<Precision,2:2><Standard Format,0>'), true);
            DataText += SetDataEtax(CurrencyCode, true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax(PaymentTerms.Description, true);
            DataText += SetDataEtax(format(pSalesInvHeader."Due Date", 0, '<Year4>-<Month,2>-<Day,2>') + 'T00:00:00', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax('', true);
            DataText += SetDataEtax(format(TotalAmt[3], 0, '<Precision,2:2><Standard Format,0>'), true);
            DataText += SetDataEtax(CurrencyCode, true);
            DataText += SetDataEtax(format(TotalAmt[4], 0, '<Precision,2:2><Standard Format,0>'), true);
            DataText += SetDataEtax(CurrencyCode, true);
            DataText += SetDataEtax(format(TotalAmt[5], 0, '<Precision,2:2><Standard Format,0>'), true);
            DataText += SetDataEtax(CurrencyCode, false);
            EtaxData := EtaxData + DataText + NewLine;
            DataText := SetDataEtax('T', True);
            DataText += SetDataEtax('1', false);
            EtaxData := EtaxData + DataText;
            ltTempblob.CreateOutStream(ltOutStream, TextEncoding::UTF8);
            ltOutStream.WriteText(EtaxData);
            ltTempblob.CreateInStream(ltInStream, TextEncoding::UTF8);
            if CallEtaxWebservice(0, pSalesInvHeader."No.", ToFileName, EtaxData, ltInStream, Format(NoSeries."NCT Etax Type Code")) then begin
                // pSalesInvHeader."NCT Etax Send to E-Tax" := true;
                // pSalesInvHeader."NCT Etax Last File Name" := COPYSTR(ltFileName, 1, 250);
                // pSalesInvHeader."NCT Etax Send By" := COPYSTR(USERID, 1, 30);
                // pSalesInvHeader."NCT Etax Send DateTime" := CurrentDateTime();
                // pSalesInvHeader."NCT Etax No. of Send" := pSalesInvHeader."NCT Etax No. of Send" + 1;
                // pSalesInvHeader."NCT Etax Status" := pSalesInvHeader."NCT Etax Status"::Completely;
                // pSalesInvHeader.Modify();
            end else begin
                // pSalesInvHeader."NCT Etax Send to E-Tax" := false;
                // pSalesInvHeader."NCT Etax Last File Name" := COPYSTR(ltFileName, 1, 250);
                // pSalesInvHeader."NCT Etax Send By" := COPYSTR(USERID, 1, 30);
                // pSalesInvHeader."NCT Etax Send DateTime" := CurrentDateTime();
                // pSalesInvHeader."NCT Etax No. of Send" := pSalesInvHeader."NCT Etax No. of Send" + 1;
                // pSalesInvHeader."NCT Etax Status" := pSalesInvHeader."NCT Etax Status"::Fail;
                // pSalesInvHeader.Modify();
            end;
            //  CreateLogEtax(pSalesInvHeader."NCT Etax Status");
        end;
    end;

    /// <summary>
    /// CreateLogEtax.
    /// </summary>
    /// <param name="EtaxStatus">Enum "NCT Etax Status".</param>
    local procedure CreateLogEtax(EtaxStatus: Enum "NCT Etax Status")
    begin
        TempEtaxLog.reset();
        if TempEtaxLog.FindSet() then
            repeat
                EtaxLog.Init();
                EtaxLog.TransferFields(TempEtaxLog, false);
                EtaxLog."Entry No." := EtaxLog.GetLastEntry();
                EtaxLog.Status := EtaxStatus;
                EtaxLog.Insert();
            until TempEtaxLog.Next() = 0;
    end;

    /// <summary>
    /// SetDataEtax.
    /// </summary>
    /// <param name="EtaxValue">Text.</param>
    /// <param name="pComma">boolean.</param>
    /// <returns>Return value of type Text.</returns>
    local procedure SetDataEtax(EtaxValue: Text; pComma: boolean): Text
    begin
        EtaxValue := DelChr(EtaxValue, '=', '"''');
        if pComma then
            exit(StrSubstNo(DataTextLbl, EtaxValue) + ',')
        else
            exit(StrSubstNo(DataTextLbl, EtaxValue));
    end;
    /// <summary>
    /// CreatePDFReport.
    /// </summary>
    /// <param name="pDocumentType">Option "Sales Invoice","Sales Credit Memo","Sales Receipt".</param>
    /// <param name="pNo">code[30].</param>
    local procedure CreatePDFReport(pDocumentType: Option "Sales Invoice","Sales Credit Memo","Sales Receipt"; pNo: code[20]; pInstream: InStream; pFileName: Text; pEtaxType: Text)
    var
        SaleInvH: Record "Sales Invoice Header";
        SalesCN: Record "Sales Cr.Memo Header";
        SalesReceiptHeader: Record "NCT Billing Receipt Header";
        TempBlob: Codeunit "Temp Blob";
        SalesInvReport: Report "NCT Sales Invoice (Post)";
        SalesCreditMemo: report "NCT Sales Credit Memo (Post)";
        SalesReceipt: Report "NCT Sales Receipt";
        ltDocumentOutStream: OutStream;
        ltDocumentInStream: InStream;
    begin
        if pDocumentType = pDocumentType::"Sales Invoice" then begin
            SaleInvH.Reset();
            SaleInvH.SetRange("No.", pNo);
            Clear(TempBlob);
            TempBlob.CreateOutStream(ltDocumentOutStream, TextEncoding::UTF8);
            Clear(SalesInvReport);
            SalesInvReport.SetTableView(SaleInvH);
            SalesInvReport.SaveAs('', ReportFormat::Pdf, ltDocumentOutStream);
            Clear(SalesInvReport);
            TempBlob.CreateInStream(ltDocumentInStream, TextEncoding::UTF8);
        end;

        if pDocumentType = pDocumentType::"Sales Credit Memo" then begin
            SalesCN.Reset();
            SalesCN.SetRange("No.", pNo);
            Clear(TempBlob);
            TempBlob.CreateOutStream(ltDocumentOutStream, TextEncoding::UTF8);
            Clear(SalesCreditMemo);
            SalesCreditMemo.SetTableView(SalesCN);
            SalesCreditMemo.SaveAs('', ReportFormat::Pdf, ltDocumentOutStream);
            Clear(SalesCreditMemo);
            TempBlob.CreateInStream(ltDocumentInStream, TextEncoding::UTF8);
        end;

        if pDocumentType = pDocumentType::"Sales Receipt" then begin
            SalesReceiptHeader.Reset();
            SalesReceiptHeader.SetRange("Document Type", SalesReceiptHeader."Document Type"::"Sales Receipt");
            SalesReceiptHeader.SetRange("No.", pNo);
            Clear(TempBlob);
            TempBlob.CreateOutStream(ltDocumentOutStream, TextEncoding::UTF8);
            Clear(SalesReceipt);
            SalesReceipt.SetTableView(SalesReceiptHeader);
            SalesReceipt.SaveAs('', ReportFormat::Pdf, ltDocumentOutStream);
            Clear(SalesReceipt);
            TempBlob.CreateInStream(ltDocumentInStream, TextEncoding::UTF8);
        end;


        TempEtaxLog.Init();
        TempEtaxLog."Entry No." := 1;
        TempEtaxLog."Document Type" := pDocumentType;
        TempEtaxLog."Document No." := pNo;
        TempEtaxLog."Last Pdf File".ImportStream(ltDocumentInStream, pFileName + '.pdf');
        TempEtaxLog."Last Text File".ImportStream(pInstream, pFileName + '.txt');
        TempEtaxLog."Etax Type" := COPYSTR(pEtaxType, 1, 250);
        TempEtaxLog."File Name" := COPYSTR(pFileName, 1, 100);
        TempEtaxLog."Create By" := CopyStr(UserId, 1, 50);
        TempEtaxLog."Create DateTime" := CurrentDateTime();
        TempEtaxLog.Insert();
    end;

    [TryFunction]
    local procedure CallEtaxWebservice(pDocumentType: Option "Sales Invoice","Sales Credit Memo","Sales Receipt"; pNo: code[20]; pfilename: text; pTextData: text; pInstream: InStream; pEtaxType: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        FileMgt: Codeunit "File Management";
        PayloadOutStream: OutStream;
        PayloadInStream: InStream;
        UrlAddress: Text[1024];
        CR: Char;
        LF: Char;
        NewLine, ToBase64_pdf, ToBase64_txt : Text;
        SelectDataDownload: array[2] of Text;
        DocumentInStream: InStream;
        DocumentOutStream: OutStream;
        PdfFileName, TextFileName : Text;
        TenantMedia: Record "Tenant Media";

    begin
        CR := 13;
        LF := 10;
        NewLine := '' + CR + LF;
        CLEAR(SelectDataDownload);
        CLEAR(PayloadOutStream);
        CLEAR(PayloadInStream);
        Clear(ToBase64_pdf);
        CLEAR(ToBase64_txt);
        TextFileName := pfilename + '.txt';
        PdfFileName := pfilename + '.pdf';

        ToBase64_txt := Base64Convert.ToBase64(pTextData);



        CreatePDFReport(pDocumentType, pNo, pInstream, pfilename, pEtaxType);


        Clear(TempBlob);
        TempEtaxLog.reset();
        TenantMedia.GET(TempEtaxLog."Last Text File".Item(1));
        TenantMedia.CalcFields(Content);
        if TenantMedia.Content.HasValue then begin
            TenantMedia.Content.CreateInStream(DocumentInStream);
            TempBlob.CreateOutStream(DocumentOutStream);
            CopyStream(DocumentOutStream, DocumentInStream);
            ToBase64_pdf := Base64Convert.ToBase64(DocumentInStream);
            FileMgt.BLOBExport(TempBlob, TextFileName, true);
        end;




        // UrlAddress := SalesReceivablesSetup."NCT Etax Service URL";
        // DSVCHttpContent.GetHeaders(HttpHeadersContent);

        // HttpHeadersContent.Clear();
        // HttpHeadersContent.Add('Content-Type', 'multipart/form-data;boundary=D365BC');
        // Clear(TempBlob);
        // TempBlob.CreateOutStream(PayloadOutStream);

        // PayloadOutStream.WriteText('--D365BC' + NewLine);
        // PayloadOutStream.WriteText('Content-Disposition: form-data; name="SellerTaxId"' + NewLine);
        // PayloadOutStream.WriteText(NewLine);
        // PayloadOutStream.WriteText(SalesReceivablesSetup."NCT Etax Seller Tax ID" + NewLine);
        // PayloadOutStream.WriteText('--D365BC' + NewLine);

        // PayloadOutStream.WriteText('Content-Disposition: form-data; name="SellerBranchId"' + NewLine);
        // PayloadOutStream.WriteText(NewLine);
        // PayloadOutStream.WriteText(SalesReceivablesSetup."NCT Etax Seller Branch ID" + NewLine);
        // PayloadOutStream.WriteText('--D365BC' + NewLine);

        // PayloadOutStream.WriteText('Content-Disposition: form-data; name="UserCode"' + NewLine);
        // PayloadOutStream.WriteText(NewLine);
        // PayloadOutStream.WriteText(SalesReceivablesSetup."NCT Etax User Code" + NewLine);
        // PayloadOutStream.WriteText('--D365BC' + NewLine);

        // PayloadOutStream.WriteText('Content-Disposition: form-data; name="AccessKey"' + NewLine);
        // PayloadOutStream.WriteText(NewLine);
        // PayloadOutStream.WriteText(SalesReceivablesSetup."NCT Etax Access Key" + NewLine);
        // PayloadOutStream.WriteText('--D365BC' + NewLine);

        // PayloadOutStream.WriteText('Content-Disposition: form-data; name="ServiceCode"' + NewLine);
        // PayloadOutStream.WriteText(NewLine);
        // PayloadOutStream.WriteText(Format(SalesReceivablesSetup."NCT Etax Service Code") + NewLine);
        // PayloadOutStream.WriteText('--D365BC' + NewLine);

        // PayloadOutStream.WriteText('Content-Disposition: form-data; name="APIKey"' + NewLine);
        // PayloadOutStream.WriteText(NewLine);
        // PayloadOutStream.WriteText(SalesReceivablesSetup.GetBlobData_APIKey() + NewLine);
        // PayloadOutStream.WriteText('--D365BC' + NewLine);


        // PayloadOutStream.WriteText('Content-Disposition: form-data; name="TextContent"' + NewLine);
        // PayloadOutStream.WriteText(NewLine);
        // PayloadOutStream.WriteText(ToBase64_txt + NewLine);
        // PayloadOutStream.WriteText('--D365BC' + NewLine);


        // PayloadOutStream.WriteText('Content-Disposition: form-data; name="PDFContent"' + NewLine);
        // PayloadOutStream.WriteText(NewLine);
        // PayloadOutStream.WriteText(ToBase64_pdf + NewLine);
        // PayloadOutStream.WriteText('--D365BC--' + NewLine);

        // TempBlob.CreateInStream(PayloadInStream);

        // DSVCHttpContent.WriteFrom(PayloadInStream);
        // DSVCHttpRequestMessage.Content := DSVCHttpContent;
        // DSVCHttpRequestMessage.SetRequestUri(UrlAddress);
        // DSVCHttpRequestMessage.Method := 'POST';
        // DSVCHttpClient.Send(DSVCHttpRequestMessage, DSVCHttpResponseMessage);
        // DSVCHttpResponseMessage.Content.ReadAs(ResponseText);
        // //  SelectDataDownload[1] := SelectStr(3, ResponseText); //xmlfile
        // if StrPos(ResponseText, 'pdfURL') <> 0 then begin
        //     DownloadFromStream(PayloadInStream, '', '', '', pfilename);
        //     ResponseText := DelChr(ResponseText, '=', '{}');
        //     // SelectDataDownload[2] := SelectStr(4, ResponseText); //pdffile
        //     // SelectDataDownload[2] := DELChr(COPYSTR(SelectDataDownload[2], 10), '=', '"');
        //     // Hyperlink(SelectDataDownload[2]);
        // end else
        //     Message(ResponseText);


    end;


    /// <summary>
    /// GetEnumValueName.
    /// </summary>
    /// <param name="pEtaxType">Enum "NCT Etax Type".</param>
    /// <returns>Return value of type Text.</returns>
    local procedure GetEnumValueName(pEtaxType: Enum "NCT Etax Type"): Text;
    var
        ltIndex: Integer;
        ltName: Text;
    begin
        ltIndex := pEtaxType.Ordinals.IndexOf(pEtaxType.AsInteger());
        pEtaxType.Names.Get(ltIndex, ltName);
        exit(ltName);
    end;

    local procedure CheckService()

    begin
        TempEtaxLog.reset();
        TempEtaxLog.DeleteAll();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.TestField("NCT Etax Access Key");
        SalesReceivablesSetup.TestField("NCT Etax API Key");
        SalesReceivablesSetup.TestField("NCT Etax Seller Branch ID");
        SalesReceivablesSetup.TestField("NCT Etax Seller Tax ID");
        SalesReceivablesSetup.TestField("NCT Etax Service Code");
        SalesReceivablesSetup.TestField("NCT Etax User Code");
        SalesReceivablesSetup.TestField("NCT Etax Service URL");

    end;

    var
        TempEtaxLog: Record "NCT Etax Log" temporary;
        EtaxLog: Record "NCT Etax Log";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CompanyInfo: Record "Company Information";
        VatBusSetup: Record "VAT Business Posting Group";
        DataTextLbl: Label '"%1"', Locked = true;
        DSVCHttpClient: HttpClient;
        DSVCHttpContent: HttpContent;
        HttpHeadersContent: HttpHeaders;
        DSVCHttpRequestMessage: HttpRequestMessage;
        DSVCHttpResponseMessage: HttpResponseMessage;
        NCTLCLFunction: Codeunit "NCT Function Center";
        ResponseText: Text;
        VATText: Text[30];

}
