/**
 *
 * Description :
 *  1.Used to calculate the average on account from all associated Credit card records
 *  2.Used to calculate the total number of credit card records associated with the account.
 *
 *  Version       Author             Date(dd/mm/yyyy)       Description
 *    1.0      Ashwini Singh          27/10/2015            To update the average fields on account
 *                                                         in correspondence to the associated credit
 *                                                         card records.
 *
 **/
public without sharing class CreditCardHandlerServiceAfter 
{
    
    //  FO-1630
    public void opportunityRollUpCreditCard(map<Id, Credit_Card__c> CredCardtNewMap, map<Id, Credit_Card__c> CredCardtOldMap)
    {
          
          set<Id> setOpportunityId = new set<Id>();
          Map<id,List<AggregateResult>> mapOppIDAgrrResultCredCrd = new Map<id,List<AggregateResult>>();
          List<Opportunity> opportunityListResult = new List<Opportunity>();
          
          Decimal sumCredCrdSal = 0;                                     
          Decimal sumTranaction = 0;                                     
          Decimal sumBatch = 0; 
           
          Decimal countCredCrdSal = 0;                                   
          Decimal countTranaction = 0;                                     
          Decimal countBatch = 0; 
           
            if (CredCardtNewMap != null)
            {
                for(Credit_Card__c credCrd: CredCardtNewMap.Values())
                {
                    if(credCrd.Opportunity__c != null){
                        setOpportunityId.add(credCrd.Opportunity__c);
                    }
                }
            }
            
            if (CredCardtOldMap != null)
            {
                for(Credit_Card__c credCrd: CredCardtOldMap.Values())
                {
                    if(credCrd.Opportunity__c != null){
                        setOpportunityId.add(credCrd.Opportunity__c);
                    }
                }
            }
            
        
              AggregateResult[] groupedResults = [SELECT Month__c,
                                                         Year__c,
                                                         Opportunity__c,
                                                         COUNT(Total_Net_Processed_All__c) numTltNetProcessAllCnt,
                                                         COUNT(Number_of_Transactions_All__c) numTransactionAllCnt,
                                                         COUNT(Batches__c) numBatchCnt,
                                                        
                                                         SUM(Total_Net_Processed_All__c) numTltNetProcessAllSum,
                                                         SUM(Number_of_Transactions_All__c) numTransactionAllSum,
                                                         SUM(Batches__c) numBatchSum
     
                                                  FROM Credit_Card__c 
                                                  WHERE Include_in_average__c = true 
                                                  AND Opportunity__c IN :setOpportunityId 
                                                  AND Month__c != NULL
                                                  AND Year__c != NULL
                                                  GROUP BY Month__c,Year__c, Opportunity__c];
                                                  
                                           
              
          // mapping is remaining.
          Map<id,Opportunity> mapIdOpp = new  Map<id,Opportunity>([SELECT Id,
                                                                          Name,
                                                                          Credit_Card_Sales__c,
                                                                          Transactions__c,
                                                                          Batches__c

                                                                    FROM Opportunity
                                                                    WHERE Id IN :setOpportunityId ]);
                                                                    
      
          for (Integer i=0 ; i < groupedResults.size();i++)  
          {
              
              if(mapOppIDAgrrResultCredCrd.containsKey((ID)groupedResults[i].get('Opportunity__c')))
              {
                  List<AggregateResult> tempAggr = mapOppIDAgrrResultCredCrd.get((ID)groupedResults[i].get('Opportunity__c'));
                  tempAggr.add(groupedResults[i]); 
              }
              else
              {
                  List<AggregateResult> lstAgrRes  = new List<AggregateResult>();
                  lstAgrRes.add(groupedResults[i]);
                  mapOppIDAgrrResultCredCrd.put((ID)groupedResults[i].get('Opportunity__c'),lstAgrRes);
              
              }
             
          }
        
        for(ID oppID: mapOppIDAgrrResultCredCrd.keySet()) 
        { 
           Opportunity opportunityObj =  mapIdOpp.get(oppID);
           if(opportunityObj != NULL)
           {
               List<AggregateResult> groupedResult = mapOppIDAgrrResultCredCrd.get(oppID);
               for (Integer i=0 ; i < groupedResult.size();i++)  
               {
                      sumCredCrdSal = sumCredCrdSal + treatNullAsZero((Decimal)groupedResult[i].get('numTltNetProcessAllSum'));
                      sumTranaction = sumTranaction + treatNullAsZero((Decimal)groupedResult[i].get('numTransactionAllSum'));
                      sumBatch = sumBatch + treatNullAsZero((Decimal)groupedResult[i].get('numBatchSum'));
                     
                      countCredCrdSal = (((Decimal)groupedResult[i].get('numTltNetProcessAllCnt') != 0) ? countCredCrdSal + 1: countCredCrdSal);
                      countTranaction = (((Decimal)groupedResult[i].get('numTransactionAllCnt') != 0) ? countTranaction + 1: countTranaction);
                      countBatch = (((Decimal)groupedResult[i].get('numBatchCnt') != 0) ? countBatch + 1: countBatch);
                }
                
                    opportunityObj.Transactions__c = sumTranaction / treatNullCntAsOne(countTranaction);
                    opportunityObj.Credit_Card_Sales__c = sumCredCrdSal / treatNullCntAsOne(countCredCrdSal);
                    opportunityObj.Batches__c = sumBatch / treatNullCntAsOne(countBatch);
                    opportunityListResult.add(opportunityObj);
               
           }
           
           
        }
       
        update opportunityListResult;
       
    }
    
    public Decimal treatNullAsZero(Decimal value)
    {
        return (value == NULL ? 0 : value);
    }
    
     public Decimal treatNullCntAsOne(Decimal value)
    {
        return (value == 0 ? 1 : value);
    }
    
    //method to calculate the average of various fields on the parent Account
    /*public void accountRollup(map<Id, Credit_Card__c> creditCardNewMap, map<Id, Credit_Card__c> creditCardOldMap){
        Set<Id> setAccount = new Set<Id>();// to  fetch  related account
        Map<String, List<Credit_Card__c>> mapYearMonthToCreditCard = new Map<String, List<Credit_Card__c>>();
        List<Credit_Card__c> bankStatmentList = new List<Credit_Card__c>();
        decimal avgProcessedCurrencyMonthly=0;
        decimal avgTransactionHoursMonthly=0;
        decimal avgMonthlyBatches=0;
        decimal totalNoOfCreditCardStmnt =0;
        list<Account> accountListResult = new list<Account>(); // list of account that will be updated
        // add to set for insert or update
        if (creditCardNewMap!= null){
            for(Credit_Card__c cardObj :creditCardNewMap.Values()){
                if(cardObj.Account__c != null){
                    setAccount.add(cardObj.Account__c); 
                }
            }
        }
        
        // add to set for update or delete 
        if (creditCardOldMap!= null){
            for(Credit_Card__c cardObj: creditCardOldMap.Values()){
                if(cardObj.Account__c != null){
                    setAccount.add(cardObj.Account__c); 
                }
            }
        }
        
        // fetching list of account to be updated along with the associated Credit card records
        List<Account> lstAcc=[Select a.Monthly_Batches_Avg__c,
                                     a.CC_transactions_Monthly_Avg__c,
                                     a.Monthly_CC_Avg_All__c,
                                    (Select Account__c,
                                            Total_Net_Processed_All__c,
                                            Number_of_Transactions_All__c,
                                            Batches__c,
                                            Year__c,
                                            Month__c
                                       From Credit_Cards1__r
                                      Where Include_in_average__c = true)
                               From Account a
                              Where a.Id IN : setAccount];
        
        //If the list of queried accounts is not empty
        if(!lstAcc.isEmpty()) {
            for(Account accountObj : lstAcc) {
                mapYearMonthToCreditCard.clear();
                avgProcessedCurrencyMonthly = 0;
                avgTransactionHoursMonthly = 0;
                avgMonthlyBatches = 0;
                totalNoOfCreditCardStmnt = 0;
                
                //if the account have associated credit card records
                if(!accountObj.Credit_Cards1__r.isEmpty()) {
                    totalNoOfCreditCardStmnt = accountObj.Credit_Cards1__r.size();
                    for(Credit_Card__c cardObj : accountObj.Credit_Cards1__r) {
                        
                        //prepare a key for map using the month and year
                        String yearMonthKey = String.ValueOf(cardObj.Year__c) + String.ValueOf(cardObj.Month__c);
                        if(!mapYearMonthToCreditCard.containsKey(yearMonthKey)) {
                            mapYearMonthToCreditCard.put(yearMonthKey, new List<Credit_Card__c>{cardObj});
                        } else {
                            bankStatmentList.clear();
                            bankStatmentList = mapYearMonthToCreditCard.get(yearMonthKey);
                            bankStatmentList.add(cardObj);
                            mapYearMonthToCreditCard.put(yearMonthKey, bankStatmentList);
                        }
                        
                        //calculate the avg of various field
                        if(cardObj.Total_Net_Processed_All__c <> Null)
                            avgProcessedCurrencyMonthly += cardObj.Total_Net_Processed_All__c;
                        if(cardObj.Number_of_Transactions_All__c <> Null)
                            avgTransactionHoursMonthly += cardObj.Number_of_Transactions_All__c;
                        if(cardObj.Batches__c <> Null) 
                            avgMonthlyBatches += cardObj.Batches__c;
                    }
                }
                    if(mapYearMonthToCreditCard.size() <> 0) {
                        //assign values to the parent account
                        accountObj.Monthly_Batches_Avg__c = avgMonthlyBatches/mapYearMonthToCreditCard.size();
                        accountObj.CC_transactions_Monthly_Avg__c = avgTransactionHoursMonthly/mapYearMonthToCreditCard.size();
                        accountObj.Monthly_CC_Avg_All__c = avgProcessedCurrencyMonthly/mapYearMonthToCreditCard.size();
                        accountObj.Number_CC_Statements_Available__c = totalNoOfCreditCardStmnt;
                        accountListResult.add(accountObj);
                    }
            }
            //update the list of account
            if(!accountListResult.isEmpty()) {
                update accountListResult;
            }
        }
    }
    */
    
  //method to calculate the average of various fields on the parent Account
  /*  public void opportunityRollup(map<Id, Credit_Card__c> creditCardNewMap, map<Id, Credit_Card__c> creditCardOldMap){
        Set<Id> setOpportunity = new Set<Id>();// to  fetch  related opportunity
        Map<String, List<Credit_Card__c>> mapYearMonthToCreditCard = new Map<String, List<Credit_Card__c>>();
        List<Credit_Card__c> bankStatmentList = new List<Credit_Card__c>();
        decimal avgProcessedCurrencyMonthly=0;
        decimal transactionAverage = 0;
        decimal batchesAverage = 0;
        list<Opportunity> opportunityListResult = new list<Opportunity>(); // list of account that will be updated
        // add to set for insert or update
        if (creditCardNewMap!= null){
            for(Credit_Card__c cardObj :creditCardNewMap.Values()){
                if(cardObj.Opportunity__c != null){
                    setOpportunity.add(cardObj.Opportunity__c);
                }
            }
        }
        
        // add to set for update or delete 
        if (creditCardOldMap!= null){
            for(Credit_Card__c cardObj: creditCardOldMap.Values()){
                if(cardObj.Opportunity__c != null){
                    setOpportunity.add(cardObj.Opportunity__c);
                }
            }
        }
        
        // fetching list of account to be updated along with the associated Credit card records
        List<Opportunity> lstOpp=[Select o.Credit_Card_Sales__c,
                                    (Select Opportunity__c,
                                            Total_Net_Processed_All__c,
                                            Number_of_Transactions_All__c,
                                            Batches__c,
                                            Year__c,
                                            Month__c
                                       From Credit_Cards__r
                                      Where Include_in_average__c = true)
                               From Opportunity o
                              Where o.Id IN : setOpportunity];

        //If the list of queried accounts is not empty
        if(!lstOpp.isEmpty()) {
            for(Opportunity opportunityObj : lstOpp) {
                mapYearMonthToCreditCard.clear();
                avgProcessedCurrencyMonthly = 0;
                transactionAverage = 0;
                batchesAverage = 0;
                //if the account have associated credit card records
                if(!opportunityObj.Credit_Cards__r.isEmpty()) {
                    for(Credit_Card__c cardObj : opportunityObj.Credit_Cards__r) {
                        
                        //prepare a key for map using the month and year
                        String yearMonthKey = String.ValueOf(cardObj.Year__c) + String.ValueOf(cardObj.Month__c);
                        if(!mapYearMonthToCreditCard.containsKey(yearMonthKey)) {
                            mapYearMonthToCreditCard.put(yearMonthKey, new List<Credit_Card__c>{cardObj});
                        } else {
                            bankStatmentList.clear();
                            bankStatmentList = mapYearMonthToCreditCard.get(yearMonthKey);
                            bankStatmentList.add(cardObj);
                            mapYearMonthToCreditCard.put(yearMonthKey, bankStatmentList);
                        }
                        
                        //calculate the avg of various field
                        if(cardObj.Total_Net_Processed_All__c <> Null)
                            avgProcessedCurrencyMonthly += cardObj.Total_Net_Processed_All__c;
                        if(cardObj.Number_of_Transactions_All__c <> Null)
                            transactionAverage += cardObj.Number_of_Transactions_All__c;
                        if(cardObj.Batches__c <> Null)
                            batchesAverage += cardObj.Batches__c;
                    }
                }
                    if(mapYearMonthToCreditCard.size() <> 0) {
                        //assign values to the parent account
                        opportunityObj.Credit_Card_Sales__c = avgProcessedCurrencyMonthly/mapYearMonthToCreditCard.size();
                        opportunityObj.Transactions__c = transactionAverage/mapYearMonthToCreditCard.size();
                        opportunityObj.Batches__c = batchesAverage/mapYearMonthToCreditCard.size();
                        opportunityListResult.add(opportunityObj);
                    }
            }
            //update the list of account
            if(!opportunityListResult.isEmpty()) {
                update opportunityListResult;
            }
        }
    }*/
}