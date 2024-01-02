pageextension 50100 CustomerListExt extends "Customer List"
{
    actions
    {
        addafter("Customer Register")
        {
            action("Process Customer Mpesa Payment")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                Image = Payment;
                trigger OnAction()
                var
                    "MpesaIntegration": Codeunit "Mpesa Integration";
                begin
                    MpesaIntegration.SendTransaction();
                end;
            }
        }
    }
}