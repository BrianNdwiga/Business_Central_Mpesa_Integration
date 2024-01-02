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

    procedure GetSetup()
    begin
        GeneralSetup.Get();
        GeneralSetup.TestField("Short Code");
        GeneralSetup.TestField("Consumer Key");
        GeneralSetup.TestField("Consumer Secret");
    end;

    procedure MpesaValues()
    begin
        BaseURL := 'https://sandbox.safaricom.co.ke/mpesa/c2b/v1/simulate';
        Amount := 1;
        MSISDN := '254708374149';
        CommandID := 'CustomerBuyGoodsOnline';
        BillRefNumber := '';
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
    begin
        GetSetup();
        MpesaAuthorization();
        MpesaValues();
        Endpoint := BaseURL;

        RequestMssg.SetRequestUri(Endpoint);

        Clear(ValueArray);
        Clear(JObject);

        JObject.Add('ShortCode', Format(GeneralSetup."Short Code"));
        JObject.Add('Amount', Format(Amount));
        JObject.Add('Msisdn', MSISDN);
        JObject.Add('CommandID', CommandID);
        JObject.Add('BillRefNumber', BillRefNumber);

        JObject.WriteTo(JcontentTxt);
        Content.WriteFrom(JcontentTxt);
        RequestMssg.Method('POST');
        Content.GetHeaders(RequestHeader);
        RequestHeader.Clear();
        RequestHeader.Remove('Content-Type');
        // RequestHeader.Add('Authorization', 'Bearer ' + AccessToken);
        // if RequestHeader.Contains('Content-Type') then
        RequestHeader.Add('Content-Type', 'application/json');
        RequestMssg.GetHeaders(RequestHeader);
        RequestHeader.Add('Authorization', 'Bearer ' + AccessToken);
        RequestMssg.Content(Content);
        Client.Send(RequestMssg, ResponseMssg);
        ResponseMssg.Content.ReadAs(ResponseText);
        Message('Request Successful!: %1', ResponseText);

        // //Read Response
        // JArray.ReadFrom(ResponseText);
        // Message(Format(ResponseObject));
        // exit;
        // Clear(ResponseObject);

        // //Read Array Count
        // for i := 0 to JArray.Count - 1 do begin
        //     JArray.Get(i, ResponseToken);
        //     ResponseObject := ResponseToken.AsObject();
        // end;

        // StudentProg."Moodle Id" := JsonAttribute(ResponseObject, 'id');
        // StudentProg."Moodle Username" := JsonAttribute(ResponseObject, 'username');
        // StudentProg.Modify();
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
}
