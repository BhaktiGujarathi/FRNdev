/*************************Details*************************
Trigger Name          :  SendEmailsCtr 
Associated Objects    :  Opportunity 
Details               :  This class is used for sending the emails to the Accounts
Any Comment           :  Done
Last modified date    :  Feb 16, 2016
***********************************************************/
public with sharing class SendEmailsCtr {

    public string selectedTemplate                 { get; set; }
    public string selectedEmail                    { get; set; }
    public string selectEmail                      { get; set; }
    public string selectedFrom                     { get; set; }
    public List<SelectOption> templateOptions      { get; set; } 
    public List<SelectOption> FromOptions          { get; set; } 
    public List<Opportunity> opps                  { get; set; }
    public List<Opportunity> oppsNew               { get; set; }
    public boolean showEmails                      { get; set; }
    public boolean showMsg                         { get; set; }
    public integer counter                         { get; set; }
    public string owner1                           { get; set; }
    public string owner2                           { get; set; }
    public boolean showError                       { get; set; }
    public boolean isNotError                      { get; set; }
    public Id storeLoginUserId;
    //ApexPages.StandardSetController setCon;
    public SendEmailsCtr(ApexPages.StandardSetController controller) {

    }
    public static String currency(String i) {
        String s = ( Decimal.valueOf(i==null||i.trim()==''?'0':i).setScale(2) + 0.001 ).format();
        return '$'+s.substring(0,s.length()-1);
    }
    public SendEmailsCtr(ApexPages.StandardController controller)
    {   
        owner1='';
        owner2='';
        showError=false;
        isNotError=false;
        oppsNew = new List<Opportunity>();
        counter = 0;                        
        String str = apexpages.currentpage().getparameters().get('ids');
        String[] arrStr = str.split(',');
        Set<String> setString = new Set<String>();
        for(String s : arrStr){
            setString.add(s);
        }
        storeLoginUserId = UserInfo.getUserId();
        showMsg = false;
        showEmails = true;
        selectedTemplate = '--None--';
        selectedEmail = '--None--';
        
        // setCon = controller;
        // opps = [select id,name,Account.name,Account.PersonEmail from Opportunity where id in : setCon.getSelected() And AccountId!=null And Account.PersonEmail!=null];
        opps = [select id,name,Account.name,Owner_1__c,Owner_1__r.Email from Opportunity where id in : setString ];
        if(opps.IsEmpty()){
            showEmails = false;
            showMsg = true;
        }else{
            Integer countOpp = 0;
            for(Opportunity op :opps){
                if(op.Owner_1__c==Null || op.Owner_1__r.Email==Null || op.Owner_1__r.Email==''){
                   if(countOpp ==0){owner1+= +op.Name; ++countOpp; }
                    else{ 
                        owner1+=', '+op.Name; 
                    }
                }else{
                    owner2+= op.Name;
                    oppsNew.add(op);
                }
            }
            //owner1+='"';
        }
        /*List<EmailTemplate> EmailTemplates = [SELECT Id,Name, DeveloperName, FolderId, Folder.DeveloperName
                                                FROM EmailTemplate where Folder.DeveloperName!='Send_Emails_From_Opportunity_List_View' and isActive =true ];
        */
        List<EmailTemplate> EmailTemplates = [SELECT Id,Name, DeveloperName, FolderId, Folder.DeveloperName
                                                FROM EmailTemplate where FolderId =: system.Label.LogACallFolderId];
        templateOptions = new List<SelectOption>();
        if(EmailTemplates.isEmpty()) {
            isNotError=true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,System.Label.SendEmailFolderEmpty));
            return;
        }
        Set<String> emailTemplateDuplicateTest = new Set<String>();

        for(EmailTemplate et : EmailTemplates){
            if(!emailTemplateDuplicateTest.contains(et.name)){
                templateOptions.add(new SelectOption(et.name, et.name));
            }    
            emailTemplateDuplicateTest.add(et.name);
            //System.debug('###### emailTemplateDuplicateTest1 == '+emailTemplateDuplicateTest);
        } 
        
        OrgWideEmailAddress[] owea = [select Id,Address  from OrgWideEmailAddress ];
        List<User> cuList = new List<User>([select id,name,Email from user where id=:UserInfo.getUserID()]);
        system.debug('==='+cuList);
        selectedEmail = cuList[0].Email;
        selectEmail = cuList[0].Email;
        
        SendEmailsTest();
    }
    public String SendEmailsTest(){
        //System.debug('###### --- Owner1 = '+Owner1);
        return Owner1;
    }
    public void SendEmails(){
        Map<String,String> oppToCon = new Map<String,String>();
        //OrgWideEmailAddress[] owea = [select Id,Address  from OrgWideEmailAddress where Address = 'edprocessing@drbank.com' ];
        List<Messaging.SendEmailResult> listEmailResult = null;
        if(selectedTemplate != '--None--'){
        User user = [Select Id, Name, Email From User Where Email =:selectedEmail and Id =:storeLoginUserId];
        //if(selectedEmail==selectEmail){
            selectedFrom = user.ID;
        //}
            /*else{
                selectedFrom = [select Id,Address  from OrgWideEmailAddress where Address =:selectedEmail].id;
            }*/
            
            System.debug('selectedFrom >>>>'+selectedFrom );
            EmailTemplate Temp = [SELECT id,name,body,Subject FROM EmailTemplate where name =: selectedTemplate ];
            System.debug('selectedFrom >>>>'+Temp );
            List<Messaging.SingleEmailMessage> emailList= new List<Messaging.SingleEmailMessage>();
            List<Task> tasks = new List<Task>();
            
            Map<Id,map<string,string>> mapBodyParamsOut = new Map<Id,map<string,string>>();
            for(Opportunity opp : opps){
                map<string,string> mapBodyParams = new map<string,string>();
                mapBodyParams.put('{!Opportunity.Account}',opp.Account.name);
                mapBodyParams.put('{!Opportunity.Name}',opp.name);
                mapBodyParamsOut.put(opp.id,mapBodyParams);
            }
            
            for(Opportunity opp : oppsNew){
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); 
              //  email.setToAddresses(new String[] {opp.Account.PersonEmail});
                //email.setSubject(temp.subject);
                if(selectedEmail!=selectEmail){
                email.setOrgWideEmailAddressId(selectedFrom);}
                email.settargetObjectID(opp.Owner_1__c);
                email.settemplateID(temp.ID);
                string plainBody = temp.body;
                for(String key : mapBodyParamsOut.get(opp.id).keyset()){
                    if(temp.body !=null){    
                        system.debug('--- i am here'+key);
                        plainBody =plainBody.replace(key , mapBodyParamsOut.get(Opp.id).get(key) == null ? '' : mapBodyParamsOut.get(Opp.id).get(key));    
                    }    
                }
                //email.setPlainTextBody(plainBody);
                emailList.add(email);
                
                Task t = new Task();
                t.Subject= 'Email sent: '+Temp.name;
                t.Activity_type__c = 'Email Sent';
                t.Status ='Completed';
                t.Priority = 'Normal';
                t.Description = plainBody ;
                t.whatId = opp.id;
                tasks.add(t);
            }
           try{
            listEmailResult = Messaging.SendEmail(emailList);
            Integer limitCalled = Limits.getEmailInvocations();
            Integer limitCanCalled = Limits.getLimitEmailInvocations();
            //counter = 0;
            for(Messaging.SendEmailResult rr: listEmailResult){
                if(rr.IsSuccess()){
                    counter = counter + 1; 
                }
            }    
            insert tasks;
           }
            catch(Exception e){
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'It seems you have exceeded your daily single email limit'));
            }
        }
        else{
            
             List<Messaging.SingleEmailMessage> emailList= new List<Messaging.SingleEmailMessage>();
             List<Task> tasks = new List<Task>();
             
             for(Opportunity opp : opps){
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); 
               // email.setToAddresses(new String[] {opp.Account.PersonEmail});
                email.setSubject('WithOut Template');
                email.setPlainTextBody('Hi '+opp.Account.name+',\n\n'+'We just tried calling you regarding your loan. Please let me know when is a good time to chat.');
                emailList.add(email);
                Task t = new Task();
                t.Subject= 'Email sent: without Template';
                t.Activity_type__c = 'Email';
                t.Status ='Completed';
                t.Priority = 'Normal';
                t.whatId = opp.id;
                tasks.add(t);
            }
            listEmailResult = Messaging.SendEmail(emailList);
            for(Messaging.SendEmailResult rr: listEmailResult){
                if(rr.IsSuccess()){
                    counter = counter + 1;    
                }
            }    
            //insert tasks;
            //delete cons;
            
        }
        PageReference pg = new PageReference('/006/o');
    }
}