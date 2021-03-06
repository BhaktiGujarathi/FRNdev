/**
 *  This class is a helper class for setting default values
 *
 *  Version     Author                      Date(DD/MM/YYYY)            Description
 *  1.0                                                                 Initial draft[]
 *  1.1         Ajinkya Hingne              17/10/2016                  Show default vals when creating new record
 *  1.2         Merul Shah                  07/11/2016                  Added to display arrows
                                                                        for field function
 */
global with sharing class GRIDReceivablesController
{
    public String OpportunityId;
    public List<Receivable__c> recLst;
    public Map<Id, Receivable__c> recFromDbMap;
    public List<ReceivableWrapper> recWrapperLst;
    public String recAggregateQueryStr = '';
    public String recFieldsString = '';
    public Set<String> recFieldsApiSet;
    public Boolean recFirstRun;
    public Boolean recIsNewBtnPress;
    public Boolean recSingleErrorOnSave;
    public String recFieldType;
    public Boolean recEditAll;

    public static Map<String, Schema.SObjectType> globalMap;
    public static Map<String, GRIDTabsSetting__mdt> customMetaDataSettingMap;

    public List<Schema.FieldSetMember> recFieldsetList                                  {get; set;}
    public Set<string> recFieldSumSet                                                   {get; set;}
    public Set<String> recCurrencyFields                                                {get; set;}
    public Map<String, Decimal> recFieldToSumMap                                        {get; set;}
    public Integer recRecordCount                                                       {get; set;}
    public Integer recBlockSize                                                         {get; set;}
    public Integer recOffsetsize                                                        {get; set;}
    public Integer recIndexToRemove                                                     {get; set;}
    public string recSortDirection                                                      {get; set;}
    public String recSortExpression                                                     {get; set;}
    public String recSortExprFieldApi                                                   {get; set;}
    public Boolean recIsRefrenceField                                                   {get; set;}
    public String recRefrenceFieldLabel                                                 {get; set;}
    public boolean recIsDisable                                                         {get; set;}
    // Editall Attribute
    public Boolean recEditAllFlag                                                       {get; set;}
    // boolean to handle save success message on navigation
    public Boolean recPageNavigated;
    public Boolean displaySortingArrow                                                  {get; set;}
    public String fieldPathResult                                                       {get; set;}
    public String currencySymbolReceivables                                             {get; set;}

    public GRIDReceivablesController()
    {
        if(GRIDOnloadStaticVariable.flipReceivable())
        {
            recIsDisable = false;
            opportunityId = Apexpages.currentPage().getParameters().get('id');
            if(opportunityId == null || opportunityId == '') {
                //ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Info, 'Opportunity does not exist.'));
                recIsDisable = true;
            }
            globalMap = GRIDOnloadStaticVariable.getGlobalMap();
            customMetaDataSettingMap = GRIDOnloadStaticVariable.getCustomMetaDataMap();

            recBlockSize = (Integer)customMetaDataSettingMap.get('Receivables').PageSize__c;
            recOffsetsize = 0;
            recLst = new List<Receivable__c>();
            recFromDbMap = new Map<Id, Receivable__c>();
            recWrapperLst = new List<ReceivableWrapper>();
            recFieldToSumMap = new Map<String, Decimal>();
            recFieldSumSet = new Set<String>();
            recCurrencyFields = new Set<String>();
            recFieldsApiSet = new Set<String>();
            recFieldsetList = new List<Schema.FieldSetMember>();
            recIsNewBtnPress = false;
            recSortDirection = 'DESC';
            recSortExpression = 'CreatedDate';
            recFieldType = '';
            currencySymbolReceivables = MultiCurrencyHelper.getUserCurrencySymbol();
            recEditAll = false;
            recPageNavigated = false;
            displaySortingArrow = true;
            fieldPathResult = '';
            Schema.DescribeSObjectResult recDescbResult = globalMap.get(customMetaDataSettingMap.get('Receivables').Object_API_Name__c).getDescribe();
            recFieldsetList = recDescbResult.FieldSets.getMap().get(customMetaDataSettingMap.get('Receivables').Fieldset_Name__c).getFields();

            GRIDUtility.ReferenceFieldWrapper refWrap = new GRIDUtility.ReferenceFieldWrapper(recFieldsetList, ' ', false);
            refWrap = GRIDUtility.isReferenceFieldPresent(refWrap);
            recIsRefrenceField = refWrap.isReferenceField;
            recRefrenceFieldLabel = refWrap.refrenceFieldLabel;

            if(!recIsRefrenceField)
            {
                recAggregateQueryStr = buildRecAggregateQuery(recFieldsetList);
                recFieldToSumMap = getRecFieldSum(recAggregateQueryStr);
                recFieldsApiSet = buildSetFromFieldListReceivable(recFieldsetList);
                if(opportunityId != null && opportunityId != '')
                    recLst = getReceivableFromDB(opportunityId, recBlockSize, recOffsetsize, recFieldsApiSet, recSortExpression, recSortDirection);
                recFirstRun = true;
            }
            setDisplaySoringArrows(recDescbResult, recFieldsetList);
        }
    }

    /**
     * To display sorting arrows for fields whose data type other than longtextares
     */
    public void setDisplaySoringArrows(
            Schema.DescribeSObjectResult descObjResult,
            List<Schema.FieldSetMember> fieldSetList
    ) {
        Map<String, Schema.SObjectField> MAP_OBJECT_FIELD = new Map<String, Schema.SObjectField>();
        for(String fieldName : descObjResult.fields.getMap().keySet()) {
            MAP_OBJECT_FIELD.put(
                descObjResult.fields.getMap().get(fieldName).getDescribe().getName(),
                descObjResult.fields.getMap().get(fieldName)
            );
        }
        for(Schema.FieldSetMember fieldSetMemb : fieldSetList) {
            if(fieldSetMemb.getType() == DisplayType.TextArea) {
                Schema.SObjectField sObjFields = MAP_OBJECT_FIELD.get(fieldSetMemb.getfieldPath());
                Schema.DescribeFieldResult descFieldResult = sObjFields.getDescribe();
                if(descFieldResult.getLength() > 255 ) {
                    displaySortingArrow = false;
                    fieldPathResult = fieldSetMemb.getfieldPath();
                }
            }
            displaySortingArrow = true;
        }
    }

    // method to build a Set of FieldApi name From List of FieldSetMember
    public Set<String> buildSetFromFieldListReceivable(List<Schema.FieldSetMember> pRecFieldsetList)
    {
        String recReferenceField;
        for(Schema.FieldSetMember fieldInstance :pRecFieldsetList)
        {
            recFieldsApiSet.add(fieldInstance.getfieldPath());
            if(String.valueOf(fieldInstance.getType()).equalsIgnoreCase('Reference'))
            {
                recReferenceField = '';
                if(fieldInstance.getfieldPath().contains('__c'))
                {
                    recReferenceField += fieldInstance.getfieldPath().substringBefore('__c')+'__r.Name';
                }
                else
                {
                    recReferenceField += fieldInstance.getfieldPath().substringBefore('Id')+'.Name';
                }
                recFieldsApiSet.add(recReferenceField);
            }
        }
        return recFieldsApiSet;
    }

    // method to build dynamic query for SUM and COUNT
    public String buildRecAggregateQuery(List<Schema.FieldSetMember> pRecFieldsetList)
    {
        recAggregateQueryStr = 'SELECT ';

        for(Schema.FieldSetMember fieldInstance :pRecFieldsetList)
        {
            if(String.valueOf(fieldInstance.getType()).equalsIgnoreCase('Currency')
               || String.valueOf(fieldInstance.getType()).equalsIgnoreCase('Double')
               || String.valueOf(fieldInstance.getType()).equalsIgnoreCase('Integer'))
            {
                recAggregateQueryStr += 'SUM('+fieldInstance.getFieldPath()+') '+fieldInstance.getFieldPath()+ ', ';
                recFieldSumSet.add(fieldInstance.getFieldPath());
            }
            if(String.valueOf(fieldInstance.getType()).equalsIgnoreCase('Currency')) {
                recCurrencyFields.add(fieldInstance.getFieldPath());
            }
            //recFieldsApiSet.add(fieldInstance.getfieldPath());
            recFieldToSumMap.put(fieldInstance.getFieldPath(), -999.999);
        }
        recAggregateQueryStr += 'COUNT(Id) recCount FROM Receivable__c Where Opportunity__c = \''+opportunityId+'\' AND Status__c != \'Cancelled\'';
        return recAggregateQueryStr;
    }

    // method to query and get the sum of numeric fields
    public Map<String, Decimal> getRecFieldSum(String pRecAggregateQueryStr)
    {
        if(opportunityId <> null && opportunityId <> '')
        {
            List<SObject> recSumQueryResult = new List<SObject>();
            recSumQueryResult = Database.query(pRecAggregateQueryStr);

            for(String fieldName :recFieldSumSet)
            {
                recFieldToSumMap.put(fieldName,0);
                if(recSumQueryResult[0].get(fieldName) != null)
                {
                    Decimal value = (Decimal)recSumQueryResult[0].get(fieldName);
                    recFieldToSumMap.put(
                        fieldName,
                        recCurrencyFields.contains(fieldName) && MultiCurrencyHelper.isMultiCurrencyEnabled()
                            ? MultiCurrencyHelper.convertToUserCurrency(value)
                            : value
                    );
                }
            }
            //recRecordCount = (Integer)recSumQueryResult[0].get('recCount');
            recRecordCount = [SELECT COUNT() FROM Receivable__c WHERE  Opportunity__c = :opportunityId];
            return recFieldToSumMap;
        }
        recRecordCount = 0;
        return null;
    }

    // method to get payables from DB
    public List<Receivable__c> getReceivableFromDB(String pOpportunityId, Integer pRecBlockSize, Integer pRecOffsetSize, Set<String> pRecFieldsApiSet,
                                             String pRecSortExpression, String pRecSortDirection)
    {
        if(pOpportunityId <> null && pOpportunityId <> '') {
            String recQueryStr = '';
            recFieldsString = MCAUtility.getStringfromSet(pRecFieldsApiSet, null);
            recQueryStr = 'Select ' +recFieldsString+
                            ' From Receivable__c Where Opportunity__c =:pOpportunityId ORDER BY '+pRecSortExpression+' '+pRecSortDirection+' NULLS LAST LIMIT '
                            +pRecBlockSize+' Offset ' +pRecOffsetSize;
            return database.query(recQueryStr);
        }
        return new List<Receivable__c>();
    }

    // method to get the wrapper list
    public List<ReceivableWrapper> getRecWrapperLst()
    {
        if(recFirstRun)
        {
            recWrapperLst = new List<ReceivableWrapper>();
        }

        if(recLst <> null && recLst.size() > 0)
        {
            if(recFirstRun)
            {
                //recWrapperLst = new List<ReceivableWrapper>();
                for (Integer i = 0; i < recLst.size(); i++)
                {
                    recWrapperLst.add(new ReceivableWrapper(recLst[i], i, recEditAllFlag));
                }
                // moved inside if condition for getting aggregate results only if firstrun is true
                //recFieldToSumMap = getRecFieldSum(recAggregateQueryStr);
                recFirstRun = false;
            }
        }
        return recWrapperLst;
    }

    // method to build a map from a list from DB
    public Map<Id, Receivable__c> getRecMapFromList(List<Receivable__c> pRecLst)
    {
        recFromDbMap.clear();
        for(Receivable__c recInstance :pRecLst)
        {
            recFromDbMap.put(recInstance.Id, recInstance);
        }
        return RecFromDbMap;
    }

    // method to create new Receivables
    public void newRec() {
        globalMap = GRIDOnloadStaticVariable.getGlobalMap();
        customMetaDataSettingMap = GRIDOnloadStaticVariable.getCustomMetaDataMap();
        Schema.DescribeSObjectResult recvblDescbResult = globalMap.get(customMetaDataSettingMap.get('Receivables').Object_API_Name__c).getDescribe();
        recIsNewBtnPress = true;
        if(!recEditAll)
        {
            saveReceivables();
        }
        else
        {
            recSingleErrorOnSave = false;
        }
        recIsNewBtnPress = false;

        if(!recSingleErrorOnSave)
        {
            // to add new record only on first page
            if(recOffsetsize <> 0)
            {
                recOffsetsize = 0;
                beginningReceivable();
            }
            Receivable__c recNew = new Receivable__c();
            DefaultValueHelper.populateValues(recNew, recFieldsetList, recvblDescbResult);
            //recNew.Due_Date__c = system.today();
            recNew.Opportunity__c = opportunityId;
            recNew.OwnerId = userinfo.getUserId();
            recNew.Status__c = pickListDefaultValueReceivable();
            //recWrapperLst.add(0, new ReceivableWrapper(recNew, null, true));
           // recLst.add(0, recNew);
            /*need to add at 0th index if list size > 0 else simple add will work*/
            if(recWrapperLst.size() > 0 && recLst.size() > 0) {
                recWrapperLst.add(0,new ReceivableWrapper(recNew, null, true));
                recLst.add(0,recNew);
            } else {
                 recWrapperLst.add(new ReceivableWrapper(recNew, null, true));
                 recLst.add(recNew);
            }

            // reindexing
            for(Integer i=0; i<recWrapperLst.size(); i++)
            {
                recWrapperLst[i].recIndex = i;
            }
        }
    }

    // method to delete payables
    public void deleteRec()
    {
        if(recWrapperLst[recIndexToRemove].rec.Id != null)
         {
            try
            {
                delete recWrapperLst[recIndexToRemove].rec;
            }
            catch(Exception e)
            {
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Info,MCAExceptionHandlerUtility.getErrorMessage(e)));
            }
         }

         recLst.remove(recIndexToRemove);
         recWrapperLst.remove(recIndexToRemove);

          //re-indexing
             for(Integer i=0;i<recWrapperLst.size();i++)
             {
               recWrapperLst[i].recIndex = i;
             }

        if(recWrapperLst.size() <= 0)
        {
            refreshReceivables();
        }
        recFieldToSumMap = getRecFieldSum(recAggregateQueryStr);
    }

    // method to cave payable
    public void saveReceivables()
    {
        String recMsgStr = '';
        String recSuccessMsgStr ='';
        recSingleErrorOnSave = false;
        Boolean recIsUpdated = false;
        recEditAll = false;
        List<Receivable__c> recListToUpdate = new List<Receivable__c>();
        Map<Integer, Integer> recErrorToWraperIndexMap = new map<Integer, Integer>();

        List<Receivable__c> recTempLst = getReceivableFromDB(
            opportunityId,
            recBlockSize,
            recOffsetsize,
            recFieldsApiSet,
            recSortExpression,
            recSortDirection
        );
        recFromDBMap = getRecMapFromList(recTempLst);

        for(ReceivableWrapper recWraperInstance :recWrapperLst) {
            Receivable__c recDBObj = recFromDBMap.get(recWraperInstance.rec.Id);
            if(recDBObj != null) {
                recIsUpdated = false;
                for(String recFieldInstance :recFieldsApiSet)
                {
                    if(!recFieldInstance.contains('.Name'))
                    {
                        recIsUpdated  = recIsUpdated 
                            ||(recWraperInstance.rec.get(recFieldInstance) != recDBObj.get(recFieldInstance));
                    }
                }
            } else {
                if(!recIsNewBtnPress) {
                    recIsUpdated = true;
                }
            }

            if(recIsUpdated) {
                recListToUpdate.add(recWraperInstance.rec);
                recErrorToWraperIndexMap.put(recListToUpdate.size()-1, recWraperInstance.recIndex);
            }
            recWraperInstance.recEdit = recEditAllFlag;
        }

        try {
            if(recListToUpdate != null && recListToUpdate.size() >0) {
                List<Database.upsertResult> results = Database.upsert(recListToUpdate, false);
                for (Integer i =0; i < results.size(); i++) {
                    if (!results[i].isSuccess())
                    {
                        for (Database.Error err : results[i].getErrors())
                        {
                             String recordError = err.getMessage();
                             /*
                             if(recordError.contains('insufficient access rights on'))
                             {
                                 recordError = 'You do not have the level of access 
                                 necessary to perform the operation you requested. 
                                 Please contact the owner of the record or your administrator 
                                 if access is necessary.';
                             }
                             else
                             {
                                recWrapperLst[recErrorToWraperIndexMap.get(i)].recEdit = true;
                             }*/
                             if(!recordError.contains('insufficient access rights on')) {
                                 recWrapperLst[recErrorToWraperIndexMap.get(i)].recEdit = true;
                             }
                             recSingleErrorOnSave = true;
                             if(results.size() > 1) {
                                recMsgStr = recMsgStr 
                                    + 'Error Record '
                                    +(recErrorToWraperIndexMap.get(i)+1)+' : '
                                   + recordError  + '<br />';
                             } else {
                                 recMsgStr = recMsgStr 
                                    + 'Error Record '
                                    +(recErrorToWraperIndexMap.get(i)+1)+' : '
                                   + recordError ;
                             }
                        }
                    }
                    else if(results[i].isSuccess())
                    {
                        if(recListToUpdate.size() > 1) {
                            recSuccessMsgStr = recSuccessMsgStr
                                + 'Success Record '
                                +(recErrorToWraperIndexMap.get(i)+1)
                                +' : '+ 'saved successfully!' + '<br />';
                        } else {
                            recSuccessMsgStr = recSuccessMsgStr
                                + 'Success Record '
                                +(recErrorToWraperIndexMap.get(i)+1)
                                +' : '+ 'saved successfully!';
                        }
                        recWrapperLst[recErrorToWraperIndexMap.get(i)].recEdit = recEditAllFlag;
                    }
                }
                recSuccessMsgStr = recSuccessMsgStr.removeEnd('<br />');
                recMsgStr = recMsgStr.removeEnd('<br />');
                if(recSingleErrorOnSave == false && !recIsNewBtnPress)
                {
                    recLst = getReceivableFromDB(
                        opportunityId,
                        recBlockSize,
                        recOffsetsize,
                        recFieldsApiSet,
                        recSortExpression,
                        recSortDirection
                    );
                    recFieldToSumMap = getRecFieldSum(recAggregateQueryStr);
                    recFirstRun = true;
                }
                if(String.isNotBlank(recMsgStr) || String.isNotBlank(recSuccessMsgStr)) {
                    if(recPageNavigated) {
                        //recPageNavigated = false;
                        recSuccessMsgStr = 'Last changes made by you were saved successfully!';
                    }
                    if(String.isNotBlank(recMsgStr)) {
                        
                        if(String.isNotBlank(recSuccessMsgStr)) {
                            ApexPages.addMessage(new Apexpages.Message(
                                ApexPages.Severity.Info,recMsgStr +'<br/>'+ recSuccessMsgStr)
                            );
                        } else {
                            ApexPages.addMessage(new Apexpages.Message(
                                ApexPages.Severity.Info,recMsgStr )
                            );
                        }
                    }else {
                        ApexPages.addMessage(new Apexpages.Message(
                            ApexPages.Severity.info, recSuccessMsgStr.removeEnd('<br />'))
                        );
                    }
                }
            }
             recPageNavigated = false;
        } catch (Exception e) {
            ApexPages.addMessage(new Apexpages.Message(
                ApexPages.Severity.error,MCAExceptionHandlerUtility.getErrorMessage(e))
            );
             recFirstRun = false;
        }
    }

    //method for the first page of list to be displayed
    public void beginningReceivable()
    {
        recPageNavigated = true;
        saveReceivables();
        if(!recSingleErrorOnSave)
        {
            recOffsetsize = 0;
            recLst = getReceivableFromDB(opportunityId, recBlockSize, recOffsetsize, recFieldsApiSet, recSortExpression, recSortDirection);
            recFirstRun = true;
        }
    }

    //method for previous page of list to be displayed
    public void previousReceivable()
    {
        recPageNavigated = true;
        saveReceivables();
        if(!recSingleErrorOnSave && recBlockSize <= recOffsetsize)
        {
            recOffsetsize = recOffsetsize - recBlockSize;
            recLst = getReceivableFromDB(opportunityId, recBlockSize, recOffsetsize, recFieldsApiSet, recSortExpression, recSortDirection);
            recFirstRun = true;
        }
    }

    //method for next page of list to be displayed
    public void nextReceivable()
    {
       recPageNavigated = true;
       saveReceivables();
        if(!recSingleErrorOnSave && recOffsetsize <= recRecordCount)
        {
            recOffsetsize = recOffsetsize + recBlockSize;
            recLst = getReceivableFromDB(opportunityId, recBlockSize, recOffsetsize, recFieldsApiSet, recSortExpression, recSortDirection);
            recFirstRun = true;
        }
    }

    //method for last page of list to be displayed
    public void endReceivable()
    {
        recPageNavigated = true;
        saveReceivables();
        if(!recSingleErrorOnSave && math.mod(recRecordCount , recBlockSize) == 0){
            recOffsetsize = recBlockSize * ((recRecordCount/recBlockSize)-1);
        } else if (!recSingleErrorOnSave && math.mod(recRecordCount , recBlockSize) != 0){
            recOffsetsize = recBlockSize * ((recRecordCount/recBlockSize));
        }

            recLst = getReceivableFromDB(opportunityId, recBlockSize, recOffsetsize, recFieldsApiSet, recSortExpression, recSortDirection);
            recFirstRun = true;
    }

    //method to sort list of Payables
    public void sortReceivables()
    {
            string recReferenceFieldName = '';
            recFieldType = Apexpages.currentPage().getParameters().get('recTypeParam');
            if(recFieldType.equalsIgnoreCase('REFERENCE'))
            {
                if(recSortExpression.contains('__c'))
                {
                    recReferenceFieldName += recSortExpression.substringBefore('__c')+'__r.Name';
                }
                else
                {
                    recReferenceFieldName += recSortExpression.substringBefore('Id')+'.Name';
                }
                recSortExpression = string.valueOf(recReferenceFieldName);
            }

            refreshReceivables();
    }

    // method to edit all Receivable
    public void editAllReceivables()
    {
        recFirstRun = false;
        recEditAll = true;
        for(Integer i=0; i< recWrapperLst.size(); i++)
        {
            recWrapperLst[i].recEdit = true;
        }
    }

    // method to refresh
    public void refreshReceivables()
    {
        recLst = getReceivableFromDB(opportunityId, recBlockSize, recOffsetsize, recFieldsApiSet, recSortExpression, recSortDirection);
        recFieldToSumMap = getRecFieldSum(recAggregateQueryStr);
        recFirstRun = true;
    }

    //method to get picklist default value
    public String pickListDefaultValueReceivable() {
        String defaultPicklistVal;
        Schema.DescribeFieldResult picklistValues = Receivable__c.Status__c.getDescribe();
        List <Schema.PicklistEntry> listPickListVal = picklistValues.getPicklistValues();
        for (Schema.PicklistEntry pickValue : listPickListVal) {
            if (pickValue.isDefaultValue())
            {
                defaultPicklistVal= pickValue.getValue();
            }
        }
        return defaultPicklistVal;
    }

    // wrapper for Receivable
    public class ReceivableWrapper
    {
        public Receivable__c rec                                                         {get;set;}
        public Integer recIndex                                                          {get;set;}
        public Boolean recEdit                                                           {get;set;}
        public ReceivableWrapper(Receivable__c recInstance, Integer pRecIndex, Boolean pRecEdit)
        {
            rec = recInstance;
            recIndex = pRecIndex;
            recEdit = pRecEdit;
        }
    }
}