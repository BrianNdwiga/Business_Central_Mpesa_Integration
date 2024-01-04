codeunit 50100 "Mpesa Integration"
{
    var
        Client: HttpClient;
        Endpoint: Text;
        ResponseText: Text;
        JcontentTxt: Text;
        BaseURL: Text;
        Amount: Integer;
        MSISDN: Text;
        CommandID: Text;
        BillRefNumber: Code[50];
        GeneralSetup: Record "General Ledger Setup";
        Base64Convert: Codeunit "Base64 Convert";
        RequestFailError: Label 'Unable to process the request through the API!';
        AccessToken: Text;
        Password: Text;
        TransactionType: Text;
        Timestamp: Text;
        PartyA: Text;
        PartyB: Integer;
        AccountReference: Text;
        TransactionDesc: Text;

    procedure GetSetup()
    begin
        GeneralSetup.Get();
        GeneralSetup.TestField("Short Code");
        GeneralSetup.TestField("Consumer Key");
        GeneralSetup.TestField("Consumer Secret");
        GeneralSetup.TestField("API Integration Type");
        GeneralSetup.TestField("CallBack URL");
    end;

    procedure MpesaValues()
    begin
        Amount := 1;
        // Check the Integration Type to build populate the values
        case GeneralSetup."API Integration Type" of
            GeneralSetup."API Integration Type"::"C2B":
                begin
                    MSISDN := '254708374149';
                    CommandID := 'CustomerBuyGoodsOnline';
                    BillRefNumber := '';
                    BaseURL := 'https://sandbox.safaricom.co.ke/mpesa/c2b/v1/simulate';
                end;
            GeneralSetup."API Integration Type"::"STK PUSH":
                begin
                    BaseURL := 'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest';
                    "Password" := 'MTc0Mzc5YmZiMjc5ZjlhYTliZGJjZjE1OGU5N2RkNzFhNDY3Y2QyZTBjODkzMDU5YjEwZjc4ZTZiNzJhZGExZWQyYzkxOTIwMTYwMjE2MTY1NjI3';
                    "Timestamp" := '20160216165627';
                    "TransactionType" := 'CustomerPayBillOnline';
                    "PartyA" := '254708374149';
                    "PartyB" := 174379;
                    "AccountReference" := 'Test';
                    "TransactionDesc" := 'Test';
                end;
        end;
    end;

    local procedure MpesaAuthorization()
    var
        HttpClient: HttpClient;
        Response: HttpResponseMessage;
        JsonString: Text;
        JsonObj: JsonObject;
        JsonTokenVar: JsonToken;
        Element: JsonToken;
        RequestMssg: HttpRequestMessage;
        ResponseMssg: HttpResponseMessage;
        RequestHeader: HttpHeaders;
    begin
        // Check if the Time is within the Access Token validity period
        AccessToken := CheckToken();

        // Get Access Token From Authorization API
        if AccessToken = '' then begin
            // Clear and set the request headers
            RequestMssg.SetRequestUri('https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials');
            RequestMssg.Method('GET');

            // Add Authorization
            RequestMssg.GetHeaders(RequestHeader);
            RequestHeader.Add('Authorization', 'Basic ' + Base64Convert.ToBase64(GeneralSetup."Consumer Key" + ':' + GeneralSetup."Consumer Secret"));

            //Sending the GET request through Auth API and getting the token
            if not HttpClient.Send(RequestMssg, Response) then
                Error(RequestFailError) else begin
                Response.Content().ReadAs(JsonString);
                if Response.IsSuccessStatusCode then begin
                    JsonTokenVar.ReadFrom(JsonString);
                    if JsonTokenVar.IsObject then begin
                        JsonObj := JsonTokenVar.AsObject();
                        JsonObj.Get('access_token', Element);
                        AccessToken := Element.AsValue().AsText();
                        CollectToken(AccessToken);
                    end;
                end else
                    Message('Request failed!: %1', JsonString);
            end;
        end;
    end;

    procedure SendTransaction()
    var
        JArray: JsonArray;
        ValueArray: JsonArray;
        ResponseToken: JsonToken;
        ResponseObject: JsonObject;
        MoodleId: Code[10];
        StudentRec: Record Customer;
        JsonMessage: Text;
        JObject: JsonObject;
        RequestMssg: HttpRequestMessage;
        ResponseMssg: HttpResponseMessage;
        RequestHeader: HttpHeaders;
        Content: HttpContent;
        i: Integer;
        JsonObject: JsonObject;
    begin
        GetSetup();
        MpesaAuthorization();
        MpesaValues();
        Endpoint := BaseURL;

        RequestMssg.SetRequestUri(Endpoint);

        Clear(ValueArray);
        Clear(JObject);

        // Check the Integration Type to build the Request Body
        case GeneralSetup."API Integration Type" of
            GeneralSetup."API Integration Type"::"C2B":
                begin
                    JObject.Add('ShortCode', Format(GeneralSetup."Short Code"));
                    JObject.Add('Amount', Format(Amount));
                    JObject.Add('Msisdn', MSISDN);
                    JObject.Add('CommandID', CommandID);
                    JObject.Add('BillRefNumber', BillRefNumber);
                end;
            GeneralSetup."API Integration Type"::"STK PUSH":
                begin
                    JObject.Add('BusinessShortCode', Format(GeneralSetup."Short Code"));
                    JObject.Add('Password', Format(Password));
                    JObject.Add('Timestamp', Timestamp);
                    JObject.Add('TransactionType', TransactionType);
                    JObject.Add('Amount', Amount);
                    JObject.Add('PartyA', PartyA);
                    JObject.Add('PartyB', Format(PartyB));
                    JObject.Add('PhoneNumber', PartyA);
                    JObject.Add('CallBackURL', GeneralSetup."CallBack URL");
                    JObject.Add('AccountReference', AccountReference);
                    JObject.Add('TransactionDesc', TransactionDesc);
                end;
        end;

        JObject.WriteTo(JcontentTxt);
        Content.WriteFrom(JcontentTxt);
        RequestMssg.Method('POST');
        Content.GetHeaders(RequestHeader);
        RequestHeader.Clear();
        RequestHeader.Remove('Content-Type');
        RequestHeader.Add('Content-Type', 'application/json');
        RequestMssg.GetHeaders(RequestHeader);
        RequestHeader.Add('Authorization', 'Bearer ' + AccessToken);
        RequestMssg.Content(Content);
        Client.Send(RequestMssg, ResponseMssg);
        ResponseMssg.Content.ReadAs(ResponseText);
        Message('Request Successful!: %1', ResponseText);

        //Read Response
        JsonObject.ReadFrom(ResponseText);

        Message(JsonAttribute(JsonObject, 'MerchantRequestID'));
    end;

    local procedure JsonAttribute(JObject: JsonObject; ObjectMember: Text): Text
    var
        ResponseToken: JsonToken;
    begin
        if JObject.Get(ObjectMember, ResponseToken) then
            exit(ResponseToken.AsValue().AsText());
    end;

    procedure CollectToken(AccessToken: Text)
    var
        TokenEntries: Record "Token Entries";
    begin
        TokenEntries.Reset();
        TokenEntries.SetRange(Code, 'access_token');
        if TokenEntries.FindFirst() then begin
            TokenEntries.Token := AccessToken;
            TokenEntries.Time := CurrentDateTime();
            TokenEntries.Modify();
        end else begin
            TokenEntries.Init();
            TokenEntries.Code := 'access_token';
            TokenEntries.Token := AccessToken;
            TokenEntries.Time := CurrentDateTime();
            TokenEntries.Insert();
        end;
    end;

    procedure CheckToken(): Text
    var
        TokenEntries: Record "Token Entries";
        ExpiryDateTime: DateTime;
    begin
        TokenEntries.Reset();
        TokenEntries.SetRange(Code, 'access_token');
        if TokenEntries.FindFirst() then begin
            // check if it's within the expiry time period
            ExpiryDateTime := TokenEntries.Time + ((1000 * 60) * 60);
            if CurrentDateTime <= ExpiryDateTime then begin
                exit(TokenEntries.Token);
            end else
                exit('');
        end;
    end;

    procedure GetTimeStamp(): Text
    var
        TimeTxt: Text;
        DateTxt: Text;
        Day: Integer;
        Month: Integer;
        Year: Integer;
    begin
        TimeTxt := Format(Time);
        TimeTxt := DelChr(TimeTxt, '=', ':');
        TimeTxt := DelChr(TimeTxt, '=', ' ');
        TimeTxt := DelChr(TimeTxt, '=', 'PM');
        TimeTxt := DelChr(TimeTxt, '=', 'AM');
        Message(TimeTxt);
        Day := Date2DWY(Today, 1);
        Month := Date2DWY(Today, 2);
        Year := Date2DWY(Today, 3);
        DateTxt := Format(Year) + AppendZeroOnValue(Month) + AppendZeroOnValue(Day) + '00';
    end;

    local procedure AppendZeroOnValue(Value: Integer): Text
    var
        ValueTxt: Text;
    begin
        ValueTxt := Format(Value);
        if StrLen(ValueTxt) <> 2 then begin
            ValueTxt := '0' + ValueTxt;
        end;
        exit(ValueTxt);
    end;
}
