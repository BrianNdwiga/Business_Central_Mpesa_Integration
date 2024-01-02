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
    }
}
