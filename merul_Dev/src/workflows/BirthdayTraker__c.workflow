<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Birthday_Reminder</fullName>
        <description>Birthday Reminder</description>
        <protected>false</protected>
        <recipients>
            <recipient>merulkumar_shah@ymail.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/SalesNewCustomerEmail</template>
    </alerts>
    <alerts>
        <fullName>Email_to_remind</fullName>
        <description>Email to remind</description>
        <protected>false</protected>
        <recipients>
            <recipient>merulkumar_shah@ymail.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/SalesNewCustomerEmail</template>
    </alerts>
    <fieldUpdates>
        <fullName>FieldUpdateForNextYear</fullName>
        <field>Status__c</field>
        <formula>&quot;Old&quot;</formula>
        <name>FieldUpdateForNextYear</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FieldUpdateToNew</fullName>
        <field>Status__c</field>
        <formula>&quot;New&quot;</formula>
        <name>FieldUpdateToNew</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>BirthdayEmailWorkflow</fullName>
        <active>false</active>
        <criteriaItems>
            <field>BirthdayTraker__c.Status__c</field>
            <operation>equals</operation>
            <value>New</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Email_to_remind</name>
                <type>Alert</type>
            </actions>
            <actions>
                <name>FieldUpdateForNextYear</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>BirthdayTraker__c.Reminder_Date__c</offsetFromField>
            <timeLength>-12</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>FieldChangeToNewAgain</fullName>
        <actions>
            <name>FieldUpdateToNew</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>BirthdayTraker__c.Status__c</field>
            <operation>equals</operation>
            <value>Old</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
