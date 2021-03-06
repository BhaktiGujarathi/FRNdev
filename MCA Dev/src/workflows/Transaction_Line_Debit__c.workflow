<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Payable_Status_to_Paid</fullName>
        <field>Status__c</field>
        <literalValue>Paid</literalValue>
        <name>Payable Status to Paid</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>Payable__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Payable_Status_to_Partial_Paid</fullName>
        <description>To change payable status to partially paid.</description>
        <field>Status__c</field>
        <literalValue>Paid - Partial</literalValue>
        <name>Payable Status to Partial Paid</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>Payable__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Test_Payable_Status_to_Paid</fullName>
        <description>testing bizfi issue</description>
        <field>Status__c</field>
        <literalValue>Paid</literalValue>
        <name>Test_Payable Status to Paid</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>Payable__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Payable_Paid_Date</fullName>
        <description>Updates the Date Paid of Payable</description>
        <field>Date_Paid__c</field>
        <formula>Today()</formula>
        <name>Update Payable Paid Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>Payable__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Transaction_line_Debit_Date</fullName>
        <description>updates the Date of Transaction Line Debit</description>
        <field>Date__c</field>
        <formula>IF( ISNULL(Date__c), TODAY(), Date__c)</formula>
        <name>Update Transaction line Debit Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Partially Paid Debits</fullName>
        <actions>
            <name>Payable_Status_to_Partial_Paid</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>To change picklist value to partial paid for transaction line debits if amount due is remaining.</description>
        <formula>Payable__r.Bill_Amount_Due__c &lt;&gt; Payable__r.Bill_Amount_Due__c</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Payable Amount Paid - Update Status To Paid</fullName>
        <actions>
            <name>Payable_Status_to_Paid</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>On Transaction Debit Line Items, 
If Payment is done then update the status to Paid on Payable</description>
        <formula>AND( Payable__r.Bill_Amount_Due__c -  Amount__c = 0)</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Test_Payable Amount Paid - Update Status To Paid</fullName>
        <actions>
            <name>Test_Payable_Status_to_Paid</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>testing bizfi issue</description>
        <formula>Amount__c = Payable__r.Bill_Amount_Due__c</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Update Payable Date Paid</fullName>
        <actions>
            <name>Update_Payable_Paid_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Transaction_line_Debit_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Transaction_Line_Debit__c.Amount__c</field>
            <operation>greaterThan</operation>
            <value>0.00</value>
        </criteriaItems>
        <description>updates Date Paid of Payable when Transaction Line Debit created or updated</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
