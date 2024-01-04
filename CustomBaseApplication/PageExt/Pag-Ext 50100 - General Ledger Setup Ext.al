pageextension 50101 "General Ledger Setup Ext" extends "General Ledger Setup"
{
    layout
    {
        addafter(Application)
        {
            group("Mpesa Integration Setup")
            {
                field("API Integration Type"; Rec."API Integration Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the API Integration Type field.';
                }
                field("Short Code"; Rec."Short Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Short Code field.';
                }
                field("Consumer Key"; Rec."Consumer Key")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Consumer Key field.';
                }
                field("Consumer Secret"; Rec."Consumer Secret")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Consumer Secret field.';
                }
                field("CallBack URL"; Rec."CallBack URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the CallBack URL field.';
                }
            }
        }
    }
}
