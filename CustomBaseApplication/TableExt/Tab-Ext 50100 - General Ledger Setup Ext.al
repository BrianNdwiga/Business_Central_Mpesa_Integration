tableextension 50100 "General Ledger Setup Ext" extends "General Ledger Setup"
{
    fields
    {
        field(50100; "Short Code"; Integer)
        {
            Caption = 'Short Code';
            DataClassification = ToBeClassified;
        }
        field(50101; "Consumer Key"; Text[50])
        {
            Caption = 'Consumer Key';
            DataClassification = ToBeClassified;
        }
        field(50102; "Consumer Secret"; Text[50])
        {
            Caption = 'Consumer Secret';
            DataClassification = ToBeClassified;
        }
        field(50103; "API Integration Type"; Option)
        {
            OptionMembers = "C2B","STK PUSH";
        }
        field(50104; "CallBack URL"; Text[2000])
        {
            DataClassification = ToBeClassified;
        }
    }
}
