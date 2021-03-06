Public class TaskHandler2{
    public static void onInsert(List<Task> NewTasks)
    {
        if(NewTasks!=null)
        {
            Set< string > ids = new Set< string >();
            for(Task t  : NewTasks)
            {
                if(t.whatId != null)
                {
                    String str =  t.whatId;
                    String str2 = str.substring(0,3);
                    if(str2 =='006')
                    {
                        ids.add(t.whatId);
                    }
                }
            }
            
             Map<Id, Opportunity > oppsMap;
             date mydate = date.today();
             oppsMap = new Map<Id, Opportunity >([select id,
                                                         Last_Activity_Comments__c,
                                                         Last_Activity_Date_Time__c,
                                                         Last_Activity_Type__c,
                                                         Last_Activity_Stage__c,
                                                         Activities_in_Current_Stage__c,
                                                         Last_Activity_User__c,
                                                         Next_Activity_Type__c,
                                                         Next_Activity_Assigned_To__c,
                                                         Next_Activity_Comments__c,
                                                         Next_Activity_Date__c,
                                                         stagename,
                                                        (select id,
                                                                subject,
                                                                Activity_Type__c,
                                                                Description,
                                                                OwnerID,
                                                                ActivityDate 
                                                        from tasks 
                                                        where status!=null 
                                                        and status != 'Completed'
                                                        and (activityDate = NUll OR activityDate >=: mydate) 
                                                        order by ActivityDate ASC NULLS LAST) 
                                                  from Opportunity 
                                                  where id in : ids]);
             
            Map< string ,  Opportunity > OppsToUpdate1 = new Map< string ,  Opportunity >();
            Map< string ,  Opportunity > OppsToUpdate2 = new Map< string ,  Opportunity >();
            for(Task t  : NewTasks)
            {
                if(t.whatId != null )
                {
                    String str =  t.whatId;
                    String str2 = str.substring(0,3);
                    if(str2=='006' && t.status != 'Completed'  )
                    {
                        Opportunity opp =  oppsMap.get(t.whatId);   
                        if(opp.tasks!= null && opp.tasks.size()>0)
                        { 
                            opp.Next_Activity_Type__c = opp.tasks[0].Activity_Type__c==null?null:opp.tasks[0].Activity_Type__c;
                            opp.Next_Activity_Assigned_To__c = opp.tasks[0].OwnerID==null?null: opp.tasks[0].OwnerID;
                            opp.Next_Activity_Date__c = opp.tasks[0].ActivityDate==null?null:opp.tasks[0].ActivityDate;
                            opp.Next_Activity_Comments__c= opp.tasks[0].Description==null?null:getActivityComment(opp.tasks[0].Description);
                        }  
                        else{
                            opp.Next_Activity_Type__c = null;
                            opp.Next_Activity_Assigned_To__c = null;
                            opp.Next_Activity_Date__c = null;
                            opp.Next_Activity_Comments__c = null;
                        }  
                        OppsToUpdate1.put(opp.id,opp);
                     }
                    
                     if(str2=='006' && t.status == 'Completed' )
                     {
                        Opportunity opp =  oppsMap.get(t.whatId);  
                        opp.Last_Activity_Type__c = t.Activity_Type__c==null?null:t.Activity_Type__c;
                        if(opp.tasks!= null && opp.tasks.size()>0)
                        { 
                            opp.Next_Activity_Type__c = opp.tasks[0].Activity_Type__c==null?null:opp.tasks[0].Activity_Type__c;
                            opp.Next_Activity_Assigned_To__c = opp.tasks[0].OwnerID==null?null:opp.tasks[0].OwnerID;
                            opp.Next_Activity_Date__c = opp.tasks[0].ActivityDate==null?null:opp.tasks[0].ActivityDate;
                            opp.Next_Activity_Comments__c= opp.tasks[0].Description==null?null:getActivityComment(opp.tasks[0].Description);
                         
                        }  
                        else{  
                            opp.Next_Activity_Type__c = null; 
                            opp.Next_Activity_Assigned_To__c = null;
                            opp.Next_Activity_Date__c = null;
                            opp.Next_Activity_Date__c= null;
                        }  
                        if(opp.stagename==null){
                            opp.Activities_in_Current_Stage__c = 0; 
                        }  
                        
                        else if(opp.stagename != null && opp.Activities_in_Current_Stage__c != null && opp.Activities_in_Current_Stage__c > 0 && opp.Last_Activity_Stage__c == opp.stagename)
                             opp.Activities_in_Current_Stage__c = opp.Activities_in_Current_Stage__c +1;
                        else
                             opp.Activities_in_Current_Stage__c = 1;
                          
                         
                        opp.Last_Activity_Stage__c = opp.stagename;
                        opp.Last_Activity_Date_Time__c=system.now();
                        opp.Last_Activity_User__c = t.OwnerId;
                        opp.Last_Activity_Comments__c = getActivityComment(t.Description);
                        OppsToUpdate2.put(opp.id,opp);
                    }
                } 
            
            }
             
            list<Opportunity> updateOpp1 = new list<Opportunity>(OppsToUpdate1.values());
            list<Opportunity> updateOpp2 = new list<Opportunity>(OppsToUpdate2.values());
            if(updateOpp1!=null && updateOpp1.size()>0)    
                update updateOpp1;
            if(updateOpp2!=null && updateOpp2.size()>0)    
                update updateOpp2;
        }
        
    }
     
    public static void onUpdate2(List<Task> NewTasks,Map<Id,Task> NewMap,Map<Id,Task> OldMap)
    {
        if(NewTasks!= null && NewMap!=null)
        {
            Set< string > ids = new Set< string >();
            for(Task t  : NewTasks)
            {
                if(t.whatId != null)
                {
                    String str =  t.whatId;
                    String str2 = str.substring(0,3);
                    if( str2 =='006' ){
                        ids.add(t.whatId);
                    }
                }
            }
            Map<Id, Opportunity > oppsMap;
            date mydate = date.today();
            oppsMap = new Map<Id, Opportunity >([select id,
                                                        Last_Activity_Comments__c,
                                                        Last_Closed_Task__c,
                                                        Last_Activity_Date_Time__c,
                                                        Last_Activity_Type__c,
                                                        Last_Activity_Stage__c,
                                                        Activities_in_Current_Stage__c,
                                                        Last_Activity_User__c,
                                                        Next_Activity_Type__c,
                                                        Next_Activity_Assigned_To__c,
                                                        Next_Activity_Comments__c,
                                                        Next_Activity_Date__c,
                                                        stagename,
                                                        (select id,
                                                                Description,
                                                                subject,
                                                                Activity_Type__c,
                                                                OwnerID,
                                                                ActivityDate 
                                                        from tasks 
                                                        where status!=null 
                                                        And status!='Completed' 
                                                        and (activityDate = NUll OR activityDate >=: mydate) 
                                                        order by ActivityDate ASC NULLS LAST) 
                                                from Opportunity 
                                                where id in : ids]);    
             
            Map<Id, Opportunity > oppsMap2;
            oppsMap2= new Map<Id, Opportunity >([select id,
                                                        Last_Activity_Comments__c,
                                                        Last_Closed_Task__c,
                                                        Last_Activity_Date_Time__c,
                                                        Last_Activity_Type__c,
                                                        Last_Activity_Stage__c,
                                                        Activities_in_Current_Stage__c,
                                                        Last_Activity_User__c,
                                                        Next_Activity_Type__c,
                                                        Next_Activity_Assigned_To__c,
                                                        Next_Activity_Comments__c,
                                                        Next_Activity_Date__c,
                                                        stagename,
                                                        (select id,
                                                                Description,
                                                                subject,
                                                                Activity_Type__c,
                                                                OwnerID,
                                                                ActivityDate 
                                                        from tasks 
                                                        where status!=null 
                                                        and (activityDate = NUll OR activityDate >=: mydate) 
                                                        order by ActivityDate ASC NULLS LAST) 
                                                from Opportunity 
                                                where id in : ids]);  
             
            Map< string ,  Opportunity > OppsToUpdate1 = new Map< string ,  Opportunity >();    
            Map< string ,  Opportunity > OppsToUpdate2 = new Map< string ,  Opportunity >();    
            for(Task t  : NewTasks)
            {
                if(t.whatId != null)
                {
                    String str =  t.whatId;
                    String str2 = str.substring(0,3);
                    if(str2=='006' && t.status != 'Completed')
                    {
                         Opportunity opp=  oppsMap.get(t.whatId);
                       //  if(opp != null){
                             if(opp.tasks!= null && opp.tasks.size()>0)
                             { 
                                 opp.Next_Activity_Type__c = opp.tasks[0].Activity_Type__c==null?null:opp.tasks[0].Activity_Type__c;
                                 opp.Next_Activity_Assigned_To__c = opp.tasks[0].OwnerID==null?null:opp.tasks[0].OwnerID;
                                 opp.Next_Activity_Date__c = opp.tasks[0].ActivityDate==null?null:opp.tasks[0].ActivityDate;
                                 opp.Next_Activity_Comments__c= opp.tasks[0].Description==null?null:getActivityComment(opp.tasks[0].Description);
                         
                             }  
                             else{
                                 opp.Next_Activity_Type__c = null;
                                 opp.Next_Activity_Assigned_To__c = null;
                                 opp.Next_Activity_Date__c = null;
                                 opp.Next_Activity_Comments__c=null;
                             }
                             OppsToUpdate1.put(opp.id,opp);
                      //   }
                     }
                     if(str2=='006' && t.status == 'Completed'){
                         Opportunity opp2 = oppsMap2.get(t.whatId);
                         Opportunity opp=  oppsMap.get(t.whatId); 
                         if(opp.tasks!= null && opp.tasks.size()>0){ 
                                 opp2.Next_Activity_Type__c = opp.tasks[0].Activity_Type__c==null?null:opp.tasks[0].Activity_Type__c;
                                 opp2.Next_Activity_Assigned_To__c = opp.tasks[0].OwnerID==null?null:opp.tasks[0].OwnerID;
                                 opp2.Next_Activity_Date__c = opp.tasks[0].ActivityDate==null?null:opp.tasks[0].ActivityDate;
                                 opp2.Next_Activity_Comments__c= opp.tasks[0].Description==null?null:getActivityComment(opp.tasks[0].Description);
                         
                         }  
                         else{opp2.Next_Activity_Type__c = null;opp2.Next_Activity_Assigned_To__c = null;opp2.Next_Activity_Date__c = null;opp2.Next_Activity_Comments__c = null;
                         }
                         OppsToUpdate2.put(opp2.id,opp2);
                     }    
                 }
             }
             list<Opportunity> updateOpp1 = new list<Opportunity>(OppsToUpdate1.values());
             list<Opportunity> updateOpp2 = new list<Opportunity>(OppsToUpdate2.values());
             if(updateOpp1!=null && updateOpp1.size()>0)    update updateOpp1;
             if(updateOpp2!=null && updateOpp2.size()>0)    update updateOpp2;
             
         }        
     }
    
     public static void onUpdate(List<Task> NewTasks,Map<Id,Task> NewMap,Map<Id,Task> OldMap){
         if(NewTasks!= null && NewMap!=null){
             Set< string > ids = new Set< string >();
            
             for(Task t  : NewTasks){
                 if(t.whatId != null){
                     String str =  t.whatId;
                     String str2 = str.substring(0,3);
                     if( str2 =='006' ){
                         ids.add(t.whatId);
                     }
                 }
             }  
             Map<Id, Opportunity > oppsMap;
             date mydate = date.today();
             oppsMap = new Map<Id, Opportunity >([select id,
                                                         Last_Activity_Comments__c,
                                                         Last_Closed_Task__c,
                                                         Last_Activity_Date_Time__c,
                                                         Last_Activity_Type__c,
                                                         Last_Activity_Stage__c,
                                                         Activities_in_Current_Stage__c,
                                                         Last_Activity_User__c,
                                                         Next_Activity_Type__c,
                                                         Next_Activity_Assigned_To__c,
                                                         Next_Activity_Comments__c,
                                                         Next_Activity_Date__c,stagename,
                                                        (select id,
                                                                subject,
                                                                Description,
                                                                Activity_Type__c,
                                                                OwnerID,
                                                                ActivityDate 
                                                        from tasks 
                                                        where status!=null And status!='Completed' 
                                                        and (activityDate = NUll OR activityDate >=: mydate) 
                                                        order by ActivityDate ASC NULLS LAST) 
                                                from Opportunity 
                                                where id in : ids]);  
             
             Map<Id, Opportunity > oppsMap2;
             oppsMap2= new Map<Id, Opportunity >([select id,
                                                        Last_Activity_Comments__c,
                                                        Last_Closed_Task__c,
                                                        Last_Activity_Date_Time__c,
                                                        Last_Activity_Type__c,
                                                        Last_Activity_Stage__c,
                                                        Activities_in_Current_Stage__c,
                                                        Last_Activity_User__c,
                                                        Next_Activity_Type__c,
                                                        Next_Activity_Assigned_To__c,
                                                        Next_Activity_Comments__c,
                                                        Next_Activity_Date__c,stagename,
                                                        (select id,
                                                                Description,
                                                                subject,
                                                                Activity_Type__c,
                                                                OwnerID,
                                                                ActivityDate 
                                                        from tasks 
                                                        where status!=null 
                                                        and (activityDate = NUll OR activityDate >=: mydate) 
                                                        order by ActivityDate ASC NULLS LAST) 
                                                from Opportunity 
                                                where id in : ids]);  
            
             Map< string ,  Opportunity > OppsToUpdate1 = new Map< string ,  Opportunity >();
             Map< string ,  Opportunity > OppsToUpdate2 = new Map< string ,  Opportunity >();
             Map< string ,  Opportunity > OppsToUpdate3 = new Map< string ,  Opportunity >();
             
            for(Task t  : NewTasks)
            {
                if(t.whatId != null)
                {
                    String str =  t.whatId;
                    String str2 = str.substring(0,3);
                    if(str2=='006' && t.status != 'Completed')
                    {
                        Opportunity opp=  oppsMap.get(t.whatId);
                        if(opp.tasks!= null && opp.tasks.size()>0)
                        { 
                            opp.Next_Activity_Type__c = opp.tasks[0].Activity_Type__c==null?null:opp.tasks[0].Activity_Type__c;
                            opp.Next_Activity_Assigned_To__c = opp.tasks[0].OwnerID==null?null:opp.tasks[0].OwnerID;
                            opp.Next_Activity_Date__c = opp.tasks[0].ActivityDate==null?null:opp.tasks[0].ActivityDate;                             
                            opp.Next_Activity_Comments__c= opp.tasks[0].Description==null?null:getActivityComment(opp.tasks[0].Description);
                         
                        }  
                        else{
                            opp.NExt_Activity_Comments__c = null; 
                            opp.Next_Activity_Type__c = null;
                            opp.Next_Activity_Assigned_To__c = null;
                            opp.Next_Activity_Date__c = null;
                        }
                        if(opp.Last_Closed_Task__c==t.id)
                        {
                            opp.Last_Closed_Task__c   = t.id;
                            opp.Last_Activity_Type__c = t.Activity_Type__c;  
                            opp.Last_Activity_User__c = t.OwnerId;
                            opp.Last_Activity_Comments__c = getActivityComment(t.Description);   
                        }
                        OppsToUpdate1.put(opp.id,opp);  
                    }
                     if(str2=='006' && (t.status=='Completed' && OldMap.get(t.id).status!='Completed') ){
                        Opportunity opp=  oppsMap.get(t.whatId);  
                        opp.Last_Closed_Task__c=t.id;
                        opp.Last_Activity_Type__c = t.Activity_Type__c;
                        if(opp.tasks!= null && opp.tasks.size()>0){ 
                            opp.Next_Activity_Type__c = opp.tasks[0].Activity_Type__c==null?null:opp.tasks[0].Activity_Type__c;
                            opp.Next_Activity_Assigned_To__c = opp.tasks[0].OwnerID==null?null:opp.tasks[0].OwnerID;
                            opp.Next_Activity_Date__c = opp.tasks[0].ActivityDate==null?null:opp.tasks[0].ActivityDate;                             
                            opp.Next_Activity_Comments__c= opp.tasks[0].Description==null?null:getActivityComment(opp.tasks[0].Description);
                         
                        }  
                        else{
                            opp.Next_Activity_Type__c = null;
                            opp.Next_Activity_Assigned_To__c = null;
                            opp.Next_Activity_Date__c = null;
                            opp.Next_Activity_Comments__c = null;
                        }  
                        if(opp.stagename==null)
                        { 
                            opp.Activities_in_Current_Stage__c = 0;
                        }  
                        
                        else if(opp.stagename != null && opp.Activities_in_Current_Stage__c != null && opp.Activities_in_Current_Stage__c > 0 && opp.Last_Activity_Stage__c == opp.stagename)
                            opp.Activities_in_Current_Stage__c = opp.Activities_in_Current_Stage__c +1;
                        else
                            opp.Activities_in_Current_Stage__c = 1;
                         
                        opp.Last_Activity_Stage__c = opp.stagename;
                        opp.Last_Activity_Date_Time__c=system.now();
                        opp.Last_Activity_User__c = t.OwnerId;
                        opp.Last_Activity_Comments__c = getActivityComment(t.Description);
                         
                        if(opp.Last_Closed_Task__c==t.id){
                            opp.Last_Closed_Task__c   = t.id;
                            opp.Last_Activity_Type__c = t.Activity_Type__c;  
                            opp.Last_Activity_User__c = t.OwnerId;
                            opp.Last_Activity_Comments__c = getActivityComment(t.Description);
                             
                        }
                        OppsToUpdate2.put(opp.id,opp);  
                     }
                     if(str2=='006'  && (t.status=='Completed' && OldMap.get(t.id).status=='Completed') )
                     {
                        Opportunity opp = oppsMap2.get(t.whatId); 
                        if(opp.Last_Closed_Task__c==t.id){
                            opp.Last_Closed_Task__c   = t.id;
                            opp.Last_Activity_Type__c = t.Activity_Type__c;  
                            opp.Last_Activity_User__c = t.OwnerId;
                            opp.Last_Activity_Comments__c = getActivityComment(t.Description);
                        }
                        OppsToUpdate3.put(opp.id,opp);  
                    }
                }
             }
            list<Opportunity> updateOpp1 = new list<Opportunity>(OppsToUpdate1.values());
            list<Opportunity> updateOpp2 = new list<Opportunity>(OppsToUpdate2.values());
            list<Opportunity> updateOpp3 = new list<Opportunity>(OppsToUpdate3.values());
            if(updateOpp1!=null && updateOpp1.size()>0)    
                update updateOpp1;
            if(updateOpp2!=null && updateOpp2.size()>0)    
                update updateOpp2;
            if(updateOpp3!=null && updateOpp3.size()>0)    
                update updateOpp3;
              
         }
     }
     

     public static String getActivityComment(String activityComment) {
        if(String.isNotBlank(activityComment) && activityComment.length() >= 255) {
            Integer trimMsgLen = Label.Activity_Comment_trimmed_message.length();
            activityComment = activityComment.left(255 - (trimMsgLen + 1)) + Label.Activity_Comment_trimmed_message;
        }
        return activityComment;
    }
}