/// <summary>
/// Codeunit DSVCEtaxFunctions (ID 70200).
/// </summary>
codeunit 70200 "DSVCEtaxFunctions"
{
    local procedure DSVCCallEtaxWebservice(UploadInStream: InStream; pfilename: text)
    var

        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        DSVCEtaxApiSetup: Record "DSVCEtaxApi Setup";
        TempBlob: Codeunit "Temp Blob";
        PayloadOutStream: OutStream;
        PayloadInStream: InStream;
        UrlAddress: Text[1024];
        CR: Char;
        LF: Char;
        NewLine: Text;
        SelectDataDownload: array[2] of Text;
    begin
        CR := 13;
        LF := 10;
        NewLine := '' + CR + LF;
        CLEAR(SelectDataDownload);
        CLEAR(PayloadOutStream);
        CLEAR(PayloadInStream);
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.TestField("DSVC URL");
        UrlAddress := SalesReceivablesSetup."DSVC URL";
        DSVCHttpContent.GetHeaders(HttpHeadersContent);

        HttpHeadersContent.Clear();
        HttpHeadersContent.Add('Content-Type', 'multipart/form-data;boundary=DSVCEtax');
        TempBlob.CreateOutStream(PayloadOutStream);
        PayloadOutStream.WriteText(StrSubstNo(BoundaryLbl, '--') + NewLine);
        DSVCEtaxApiSetup.reset();
        if DSVCEtaxApiSetup.FindSet() then
            repeat
                PayloadOutStream.WriteText(StrSubstNo(ContentTypeLbl, DSVCEtaxApiSetup."DSVC API Name") + NewLine);
                PayloadOutStream.WriteText(NewLine);
                PayloadOutStream.WriteText(DSVCEtaxApiSetup."DSVC API Value" + NewLine);
                PayloadOutStream.WriteText(StrSubstNo(BoundaryLbl, '--') + NewLine);
            until DSVCEtaxApiSetup.next() = 0
        else
            ERROR('Nothing to Setup on E-Tax Api Setup Table');
        PayloadOutStream.WriteText('Content-Disposition: form-data; name="' + TextContentLbl + '"; fileName="' + pfilename + '"' + NewLine);
        PayloadOutStream.WriteText('Content-Type: application/octet-stream' + NewLine);
        PayloadOutStream.WriteText(NewLine);
        CopyStream(PayloadOutStream, UploadInStream);
        PayloadOutStream.WriteText(NewLine);
        PayloadOutStream.WriteText(StrSubstNo(BoundaryLbl, '--'));
        TempBlob.CreateInStream(PayloadInStream);
        DSVCHttpContent.WriteFrom(PayloadInStream);
        DSVCHttpRequestMessage.Content := DSVCHttpContent;
        DSVCHttpRequestMessage.SetRequestUri(UrlAddress);
        DSVCHttpRequestMessage.Method := 'POST';
        DSVCHttpClient.Send(DSVCHttpRequestMessage, DSVCHttpResponseMessage);
        DSVCHttpResponseMessage.Content.ReadAs(ResponseText);
        //  SelectDataDownload[1] := SelectStr(3, ResponseText); //xmlfile
        if StrPos(ResponseText, 'pdfURL') <> 0 then begin
            //DownloadFromStream(PayloadInStream, '', '', '', pfilename);
            ResponseText := DelChr(ResponseText, '=', '{}');
            SelectDataDownload[2] := SelectStr(4, ResponseText); //pdffile
            SelectDataDownload[2] := DELChr(COPYSTR(SelectDataDownload[2], 10), '=', '"');
            Hyperlink(SelectDataDownload[2]);
        end else
            Message(ResponseText);
    end;

    /// <summary>
    /// DSVCWriteText.
    /// </summary>
    /// <param name="SalesHeader">VAR Record "Sales Header".</param>
    procedure DSVCWriteText(var SalesHeader: Record "Sales Header")
    var
        CompanyInformation: Record "Company Information";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        DSVCItem: Record Item;
        Itemcategory: Record "Item Category";
        PaymentTerms: Record "Payment Terms";
        TempBlob: Codeunit "Temp Blob";
        DSVCOutStream: OutStream;
        DSVCInStream: InStream;
        FileName: Text[1024];
        DataText: Text;
        LineNo, TotalSalesLine : Integer;
        CurrencyCode: code[10];
        BranchCode: Code[12];
    begin
        LineNo := 0;
        SalesHeader.CalcFields(Amount, "Amount Including VAT");
        if not PaymentTerms.GET(SalesHeader."Payment Terms Code") then
            PaymentTerms.Init();
        CurrencyCode := COPYSTR(SalesHeader."Currency Code", 1, 3);
        if SalesHeader."Currency Code" = '' then
            CurrencyCode := 'THB';
        SalesLine.reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Shipment No.", '<>%1', '');
        if SalesLine.FindFirst() then;
        if not SalesShipmentHeader.GET(SalesLine."Shipment No.") then
            SalesShipmentHeader.init();

        CLEAR(DataText);
        CompanyInformation.GET();
        BranchCode := CompanyInformation."DSVC Etax Branch Code";
        if CompanyInformation."DSVC Etax Branch Code" = '' then
            BranchCode := '00000';
        FileName := SalesHeader."No." + '_' + format(Today, 0, '<Day,2><Month,2><Year4>') + '.txt';
        TempBlob.CreateOutStream(DSVCOutStream);
        DataText := DSVCSetDataEtax('C', true);
        DataText += DSVCSetDataEtax(CompanyInformation."VAT Registration No.", true);
        DataText += DSVCSetDataEtax(BranchCode, true);
        DataText += DSVCSetDataEtax(FileName, false);
        DSVCOutStream.WriteText(DataText);
        DataText := DSVCSetDataEtax('H', true);
        DataText += DSVCSetDataEtax('T02', true);
        DataText += DSVCSetDataEtax('ใบแจ้งหนี้', true);
        DataText += DSVCSetDataEtax(SalesHeader."No.", true);
        DataText += DSVCSetDataEtax(format(TODAY, 0, '<Year4>-<Month,2>-<Day,2>') + 'T' + FORMAT(TIME, 0, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'), true);
        DataText += DSVCSetDataEtax('', true);
        DataText += DSVCSetDataEtax('', true);
        DataText += DSVCSetDataEtax(SalesHeader."External Document No.", true);
        DataText += DSVCSetDataEtax(format(SalesHeader."Document Date", 0, '<Year4>-<Month,2>-<Day,2>') + 'T' + FORMAT(TIME, 0, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'), true);
        DataText += DSVCSetDataEtax('T02', true);
        DataText += DSVCSetDataEtax('', true);
        DataText += DSVCSetDataEtax('', true);
        DataText += DSVCSetDataEtax(SalesShipmentHeader."Order No.", true);
        DataText += DSVCSetDataEtax(format(SalesShipmentHeader."Document Date", 0, '<Year4>-<Month,2>-<Day,2>') + 'T' + FORMAT(TIME, 0, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'), true);
        DataText += DSVCSetDataEtax('IV', false);
        DSVCOutStream.WriteText(DataText);
        DataText := DSVCSetDataEtax('B', true);
        DataText += DSVCSetDataEtax(SalesHeader."Sell-to Customer No.", true);
        DataText += DSVCSetDataEtax(SalesHeader."Sell-to Customer Name" + ' ' + SalesHeader."Sell-to Customer Name 2", true);
        DataText += DSVCSetDataEtax('TXID', true);
        DataText += DSVCSetDataEtax(DelChr(SalesHeader."VAT Registration No.", '=', '-'), true);
        DataText += DSVCSetDataEtax('00000', true);
        DataText += DSVCSetDataEtax(SalesHeader."Sell-to Contact", true);
        DataText += DSVCSetDataEtax('', true);
        DataText += DSVCSetDataEtax(SalesHeader."Sell-to E-Mail", true);
        DataText += DSVCSetDataEtax(SalesHeader."Sell-to Phone No.", true);
        DataText += DSVCSetDataEtax(SalesHeader."Sell-to Post Code", true);
        DataText += DSVCSetDataEtax('', true);
        DataText += DSVCSetDataEtax('', true);
        DataText += DSVCSetDataEtax(SalesHeader."Sell-to Address" + ' ' + SalesHeader."Sell-to Address 2", true);
        DataText += DSVCSetDataEtax('', true);
        DataText += DSVCSetDataEtax('', true);
        DataText += DSVCSetDataEtax('', true);
        DataText += DSVCSetDataEtax('', true);
        DataText += DSVCSetDataEtax('', true);
        DataText += DSVCSetDataEtax('', true);
        DataText += DSVCSetDataEtax('', true);
        DataText += DSVCSetDataEtax('', true);
        DataText += DSVCSetDataEtax('', true);
        DataText += DSVCSetDataEtax(SalesHeader."Sell-to Post Code", true);
        DataText += DSVCSetDataEtax(SalesHeader."Sell-to City", true);
        DataText += DSVCSetDataEtax(SalesHeader."Sell-to Country/Region Code", false);
        DSVCOutStream.WriteText(DataText);
        SalesLine.reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("No.", '<>%1', '');
        TotalSalesLine := SalesLine.count;
        if SalesLine.FindSet() then begin
            repeat
                LineNo += 1;
                if not DSVCItem.GET(SalesLine."No.") then
                    DSVCItem.init();
                if not Itemcategory.GET(DSVCItem."Item Category Code") then
                    Itemcategory.Init();

                DataText := DSVCSetDataEtax('L', true);
                DataText += DSVCSetDataEtax(format(LineNo), true);
                DataText += DSVCSetDataEtax(SalesLine."No.", true);
                DataText += DSVCSetDataEtax(SalesLine.Description + ' ' + SalesLine."Description 2", true);
                DataText += DSVCSetDataEtax('', true);
                DataText += DSVCSetDataEtax('', true);
                DataText += DSVCSetDataEtax('', true);
                DataText += DSVCSetDataEtax(DSVCItem."Item Category Code", true);
                DataText += DSVCSetDataEtax(Itemcategory.Description, true);
                DataText += DSVCSetDataEtax('', true);
                DataText += DSVCSetDataEtax(format(SalesLine."Unit Price", 0, '<Precision,2:2><Standard Format,0>'), true);
                DataText += DSVCSetDataEtax(CurrencyCode, true);
                DataText += DSVCSetDataEtax('', true);
                DataText += DSVCSetDataEtax(format(SalesLine."Line Discount Amount", 0, '<Precision,2:2><Standard Format,0>'), true);
                if SalesLine."Line Discount Amount" <> 0 then
                    DataText += DSVCSetDataEtax(CurrencyCode, true)
                else
                    DataText += DSVCSetDataEtax('', true);
                DataText += DSVCSetDataEtax('', true);
                DataText += DSVCSetDataEtax('', true);
                DataText += DSVCSetDataEtax(format(SalesLine.Quantity), true);
                DataText += DSVCSetDataEtax(SalesLine."Unit of Measure Code", true);
                DataText += DSVCSetDataEtax(format(SalesLine."Qty. per Unit of Measure"), true);
                DataText += DSVCSetDataEtax(format(SalesLine."VAT %"), true);
                DataText += DSVCSetDataEtax(format(SalesLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
                DataText += DSVCSetDataEtax(CurrencyCode, true);
                DataText += DSVCSetDataEtax(format(SalesLine."Amount Including VAT" - SalesLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
                DataText += DSVCSetDataEtax(CurrencyCode, true);
                DataText += DSVCSetDataEtax('', true);
                DataText += DSVCSetDataEtax('', true);
                DataText += DSVCSetDataEtax('', true);
                DataText += DSVCSetDataEtax('', true);
                DataText += DSVCSetDataEtax('', true);
                DataText += DSVCSetDataEtax(format(SalesLine."Amount Including VAT" - SalesLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
                DataText += DSVCSetDataEtax(CurrencyCode, true);
                DataText += DSVCSetDataEtax(format(SalesLine.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
                DataText += DSVCSetDataEtax(CurrencyCode, true);
                DataText += DSVCSetDataEtax(format(SalesLine."Amount Including VAT", 0, '<Precision,2:2><Standard Format,0>'), true);
                if TotalSalesLine <> LineNo then
                    DataText += DSVCSetDataEtax(CurrencyCode, true)
                else
                    DataText += DSVCSetDataEtax(CurrencyCode, false);
                DSVCOutStream.WriteText(DataText);
            until SalesLine.next() = 0;
            DataText := DSVCSetDataEtax('F', true);
            DataText += DSVCSetDataEtax(format(TotalSalesLine), true);
            DataText += DSVCSetDataEtax('', true);
            DataText += DSVCSetDataEtax(CurrencyCode, true);
            DataText += DSVCSetDataEtax(SalesLine."VAT Prod. Posting Group", true);
            DataText += DSVCSetDataEtax(format(SalesLine."VAT %"), true);
            DataText += DSVCSetDataEtax(format(SalesHeader.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
            DataText += DSVCSetDataEtax(CurrencyCode, true);
            DataText += DSVCSetDataEtax(format(SalesHeader."Amount Including VAT" - SalesHeader.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
            DataText += DSVCSetDataEtax(CurrencyCode, true);
            DataText += DSVCSetDataEtax('', true);
            DataText += DSVCSetDataEtax('', true);
            DataText += DSVCSetDataEtax('', true);
            DataText += DSVCSetDataEtax('', true);
            DataText += DSVCSetDataEtax('', true);
            DataText += DSVCSetDataEtax('', true);
            DataText += DSVCSetDataEtax(PaymentTerms.Description, true);
            DataText += DSVCSetDataEtax(format(SalesHeader."Due Date", 0, '<Year4>-<Month,2>-<Day,2>') + 'T' + FORMAT(TIME, 0, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'), true);
            DataText += DSVCSetDataEtax('', true);
            DataText += DSVCSetDataEtax('', true);
            DataText += DSVCSetDataEtax('', true);
            DataText += DSVCSetDataEtax('', true);
            DataText += DSVCSetDataEtax('', true);
            DataText += DSVCSetDataEtax('', true);
            DataText += DSVCSetDataEtax('', true);
            DataText += DSVCSetDataEtax('', true);
            DataText += DSVCSetDataEtax('', true);
            DataText += DSVCSetDataEtax('', true);
            DataText += DSVCSetDataEtax(format(SalesHeader.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
            DataText += DSVCSetDataEtax(CurrencyCode, true);
            DataText += DSVCSetDataEtax(format(SalesHeader."Amount Including VAT" - SalesHeader.Amount, 0, '<Precision,2:2><Standard Format,0>'), true);
            DataText += DSVCSetDataEtax(CurrencyCode, true);
            DataText += DSVCSetDataEtax(format(SalesHeader."Amount Including VAT", 0, '<Precision,2:2><Standard Format,0>'), true);
            DataText += DSVCSetDataEtax(CurrencyCode, false);
        end else
            ERROR('Nothing Create E-Tax');
        DSVCOutStream.WriteText(DataText);
        DataText := DSVCSetDataEtax('T', True);
        DataText += DSVCSetDataEtax(format(SalesHeader.Count), false);
        DSVCOutStream.WriteText(DataText);
        TempBlob.CreateInStream(DSVCInStream, TextEncoding::UTF8);
        DSVCCallEtaxWebservice(DSVCInStream, filename);
        SalesHeader."DSVC Generate E-Tax" := true;
        SalesHeader."DSVC Generate E-Tax by" := COPYSTR(USERID, 1, 30);
        SalesHeader."DSVC Generate E-Tax DateTime" := CurrentDateTime();
        SalesHeader."DSVC E-Tax FileName" := FileName;
        SalesHeader.Modify();
        Message('Successfully');
    end;

    local procedure DSVCSetDataEtax(EtaxValue: Text; pComma: boolean): Text
    begin
        EtaxValue := DelChr(EtaxValue, '=', '"''');
        if pComma then
            exit(StrSubstNo(DataTextLbl, EtaxValue) + ',')
        else
            exit(StrSubstNo(DataTextLbl, EtaxValue));
    end;

    var

        DSVCHttpClient: HttpClient;
        DSVCHttpContent: HttpContent;
        HttpHeadersContent: HttpHeaders;
        DSVCHttpRequestMessage: HttpRequestMessage;
        DSVCHttpResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        BoundaryLbl: Label '%1DSVCEtax', Locked = true;
        ContentTypeLbl: Label 'Content-Disposition: form-data; name="%1"', Locked = true;
        DataTextLbl: Label '"%1"', Locked = true;
        TextContentLbl: Label 'TextContent', Locked = true;

}