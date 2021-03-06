/**
 *  This class is a helper class for setting default values
 *
 *  Version     Author                      Date(DD/MM/YYYY)            Description
 *  1.0                                                                 Initial draft[]
 *  1.1         Ajinkya Hingne              17/10/2016                  Show default vals when creating new record
 *  1.2         Merul Shah                  07/11/2016                  Added to display arrows
                                                                        for field function
 */

global with sharing class GRIDOffersController {
    public String OpportunityId;
    public List<Offer__c> offrLst;
    public Map<Id, Offer__c> offrFromDbMap;
    public List<OfferWrapper> offrWrapperLst;
    public String offrAggregateQueryStr = '';
    public String offrFieldsString = '';
    public Set<String> offrFieldsApiSet;
    public Boolean offrFirstRun;
    public Boolean offrIsNewBtnPress;
    public Boolean offrSingleErrorOnSave;
    public String offrFieldType;
    public Boolean offrEditAll;

    public static Map<String, Schema.SObjectType> globalMap;
    public static Map<String, GRIDTabsSetting__mdt> customMetaDataSettingMap;

    public List<Schema.FieldSetMember> offrFieldsetList                                 {get; set;}
    public Set<String> offrFieldSumSet                                                  {get; set;}
    public Set<String> offrCurrencyFields                                               {get; set;}
    public Map<String, Decimal> offrFieldToMaxMap                                       {get; set;}
    public Map<String, Decimal> offrFieldToMinMap                                       {get; set;}
    public Integer offrRecordCount                                                      {get; set;}
    public Integer offrBlockSize                                                        {get; set;}
    public Integer offrOffsetsize                                                       {get; set;}
    public Integer offrIndexToRemove                                                    {get; set;}
    public string offrSortDirection                                                     {get; set;}
    public String offrSortExpression                                                    {get; set;}
    public Opportunity opportunityObj                                                   {get; set;}
    public String sendOfferButtonURL                                                    {get; set;}
    public String dewButtonURL                                                          {get; set;}
    public String offrSortExprFieldApi                                                  {get; set;}
    public Boolean offerIsRefrenceField                                                 {get; set;}
    public String  offerRefrenceFieldLabel                                              {get; set;}
    public boolean offerisDisable                                                       {get; set;}
    public List<Submission__c> offrSubmissionList                                       {get; set;}
    public List<SelectOption> offrSubmissionOptions                                     {get; set;}
    public String offrAccountId                                                         {get; set;}
    public Boolean offrIsAvailable                                                      {get; set;}
    public String offrOppId                                                             {get; set;}
    // Editall Attribute
    public Boolean offrEditAllFlag                                                      {get; set;}
    // boolean to handle save success message on navigation
    public Boolean offrPageNavigated;
    public Boolean displaySortingArrow                                                  {get; set;}
    public String fieldPathResult                                                       {get; set;}
    public Boolean isConfirmMsgOffers                                                   {get; set;}
    public String errorMsgOffers                                                        {get; set;}
    public String mcaNamePrefix;
    public String configureSettingFromAddress                                           {get; set;}
    public String currencySymbol                                                        {get; set;}

    public GRIDOffersController()
    {
        if(GRIDOnloadStaticVariable.flipOffer())
        {
            mcaNamePrefix = ((System.Label.MCANamePrefix == 'McaApp__') ? System.Label.MCANamePrefix : '');
            offerisDisable = false;
            offrRecordCount = 0;
            opportunityObj = new Opportunity();
            opportunityId = Apexpages.currentPage().getParameters().get('id');
            if(opportunityId == null || opportunityId == '') {
                offerisDisable = true;
            } else {
                opportunityObj = [SELECT Id
                                   , Name
                                   , StageName
                                   , AccountId
                                   , Owner_1__c
                                   , Owner_1__r.Email
                                   , ISO__c
                                   , ISO_Sales_Rep__c
                                   , ISO__r.Email__c
                                   , ISO_Sales_Rep__r.Email
                              FROM Opportunity
                              WHERE Id =: opportunityId];

                offrAccountId = opportunityObj.AccountId;
                offrOppId = opportunityId;
            }

            globalMap = GRIDOnloadStaticVariable.getGlobalMap();
            customMetaDataSettingMap = GRIDOnloadStaticVariable.getCustomMetaDataMap();

            offrBlockSize = (Integer)customMetaDataSettingMap.get('Offers').PageSize__c;
            offrOffsetsize = 0;
            displaySortingArrow = true;
            fieldPathResult = '';
            currencySymbol = MultiCurrencyHelper.getUserCurrencySymbol();
            offrLst = new List<Offer__c>();
            offrFromDbMap = new Map<Id, Offer__c>();
            offrWrapperLst = new List<OfferWrapper>();
            offrFieldToMaxMap = new Map<String, Decimal>();
            offrFieldToMinMap = new Map<String, Decimal>();
            offrFieldSumSet = new Set<String>();
            offrCurrencyFields = new Set<String>();
            offrFieldsApiSet = new Set<String>();
            offrFieldsetList = new List<Schema.FieldSetMember>();
            offrSubmissionList = new List<Submission__c> ();
            offrSubmissionOptions = new List<SelectOption>();

            offrIsNewBtnPress = false;
            offrSortDirection = 'DESC';
            offrSortExpression = 'CreatedDate';
            offrFieldType = '';
            offrEditAll = false;
            offrIsAvailable = false;
            offrPageNavigated = false;

            Schema.DescribeSObjectResult offrDescbResult = globalMap.get(customMetaDataSettingMap.get('Offers').Object_API_Name__c).getDescribe();
            offrFieldsetList = offrDescbResult.FieldSets.getMap().get(customMetaDataSettingMap.get('Offers').Fieldset_Name__c).getFields();

            GRIDUtility.ReferenceFieldWrapper refWrap = new GRIDUtility.ReferenceFieldWrapper(offrFieldsetList, '', false);
            refWrap = GRIDUtility.isReferenceFieldPresent(refWrap);
            offerIsRefrenceField = refWrap.isReferenceField;
            offerRefrenceFieldLabel = refWrap.refrenceFieldLabel;

            if(!offerIsRefrenceField)
            {
                offrAggregateQueryStr = buildOfferAggregateQuery(offrFieldsetList);
                offrFieldsApiSet = buildSetFromFieldListOffer(offrFieldsetList);
                 if(opportunityId != null && opportunityId != '')
                 {
                    offrLst = getOfferFromDB(opportunityId, offrBlockSize, offrOffsetsize, offrFieldsApiSet, offrSortExpression, offrSortDirection);
                    getSubmissionsPickListVal();
                 }
                offrFirstRun = true;
                if(!offrLst.isempty() && offrLst.size() > 0)
                {
                    offrIsAvailable = true;
                }
            }
            setDisplaySoringArrows(offrDescbResult, offrFieldsetList);
            /*sendOfferButtonURL = '/_ui/core/email/author/EmailAuthor?p3_lkid='+opportunityObj.Id
            +'&retURL=%2F'+opportunityObj.Id+'&template_id='+system.Label.GRIDEmailOfferTemplateId
            +'&p2='+opportunityObj.Owner_1__c+'&p2_lkid='+ opportunityObj.Owner_1__c;*/
            dewButtonURL = '/apex/'+mcaNamePrefix+'CreateContract?accId='
                + opportunityObj.AccountId+'&id='+opportunityObj.id+'&stage=Renewal+Requested';
            FO_Email_Settings__c offersCustmStng = FO_Email_Settings__c.getValues('Email Offers');
            EmailConfig configStng = new EmailConfig();
            configureSettingFromAddress = configStng.fetchOrgWideEmail(offersCustmStng);
            errorMsgOffers = configStng.validateData(offersCustmStng, opportunityObj);
            isConfirmMsgOffers = configStng.isConfirmMsg;
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
        for(Schema.FieldSetMember fieldOffr : fieldSetList) {
            if(fieldOffr.getType() == DisplayType.TextArea) {
                Schema.SObjectField sObjFields = MAP_OBJECT_FIELD.get(fieldOffr.getfieldPath());
                Schema.DescribeFieldResult descFieldResult = sObjFields.getDescribe();
                if(descFieldResult.getLength() > 255 ) {
                    displaySortingArrow = false;
                    fieldPathResult = fieldOffr.getfieldPath();
                }
            }
            displaySortingArrow = true;
        }
    }

    // method to build a Set of FieldApi name From List of FieldSetMember
    public Set<String> buildSetFromFieldListOffer(List<Schema.FieldSetMember> pOffrFieldsetList)
    {
        String offrReferenceField;
        for(Schema.FieldSetMember fieldInstance :pOffrFieldsetList)
        {

            offrFieldsApiSet.add(fieldInstance.getfieldPath());
            if(String.valueOf(fieldInstance.getType()).equalsIgnoreCase('Reference'))
            {
                offrReferenceField = '';
                if(fieldInstance.getfieldPath().contains('__c'))
                {
                    offrReferenceField += fieldInstance.getfieldPath().substringBefore('__c')+'__r.Name';
                }
                else
                {
                    offrReferenceField += fieldInstance.getfieldPath().substringBefore('Id')+'.Name';
                }
                offrFieldsApiSet.add(offrReferenceField);
            }
        }
        return offrFieldsApiSet;
    }

    // method to build dynamic query for SUM and COUNT
    public String buildOfferAggregateQuery(List<Schema.FieldSetMember> pOffrFieldsetList)
    {
        offrAggregateQueryStr = 'SELECT ';

        for(Schema.FieldSetMember fieldInstance :pOffrFieldsetList)
        {
            if(String.valueOf(fieldInstance.getType()).equalsIgnoreCase('Currency')
               || String.valueOf(fieldInstance.getType()).equalsIgnoreCase('Double')
               || String.valueOf(fieldInstance.getType()).equalsIgnoreCase('Integer'))
            {
                offrAggregateQueryStr += 'MAX('+fieldInstance.getFieldPath()+') '+'Max'+fieldInstance.getFieldPath()+ ', ';
                offrAggregateQueryStr += 'MIN('+fieldInstance.getFieldPath()+') '+'Min'+fieldInstance.getFieldPath()+ ', ';
                offrFieldSumSet.add(fieldInstance.getFieldPath());

            }
            if(String.valueOf(fieldInstance.getType()).equalsIgnoreCase('Currency')) {
                offrCurrencyFields.add(fieldInstance.getFieldPath());
            }
            offrFieldToMaxMap.put(fieldInstance.getFieldPath(), -999.999);
            offrFieldToMinMap.put(fieldInstance.getFieldPath(), -999.999);
        }
        offrAggregateQueryStr += 'COUNT(Id) offrCount FROM Offer__c Where Opportunity__c = \''+opportunityId+'\'';
        return offrAggregateQueryStr;
    }

    // method to query and get the sum of numeric fields
    public void getOfferFieldSum(String pOffrAggregateQueryStr)
    {
        if(opportunityId <> null && opportunityId <> '')
        {
            List<SObject> offrSumQueryResult = new List<SObject>();
            offrSumQueryResult = Database.query(pOffrAggregateQueryStr);

            for(String fieldName :offrFieldSumSet)
            {
                 offrFieldToMinMap.put(fieldName, 0);
                 offrFieldToMaxMap.put(fieldName, 0);

                if(offrSumQueryResult[0].get('Min'+fieldName) != null)
                {
                    Decimal minValue = (Decimal)offrSumQueryResult[0].get('Min'+fieldName);
                    offrFieldToMinMap.put(
                        fieldName,
                        offrCurrencyFields.contains(fieldName) && MultiCurrencyHelper.isMultiCurrencyEnabled()
                            ? MultiCurrencyHelper.convertToUserCurrency(minValue)
                            : minValue
                    );
                }
                if(offrSumQueryResult[0].get('Max'+fieldName) != null)
                {
                    Decimal maxValue = (Decimal)offrSumQueryResult[0].get('Max'+fieldName);
                    offrFieldToMaxMap.put(
                        fieldName,
                        offrCurrencyFields.contains(fieldName) && MultiCurrencyHelper.isMultiCurrencyEnabled()
                            ? MultiCurrencyHelper.convertToUserCurrency(maxValue)
                            : maxValue
                    );
                }
            }
            offrRecordCount = (Integer)offrSumQueryResult[0].get('offrCount');
        }
        else
        {
             offrRecordCount = 0;
             offrFieldToMaxMap = null;
             offrFieldToMinMap = null;
         }
    }

    // method to get offrables from DB
    public List<Offer__c> getOfferFromDB(String pOpportunityId, Integer pOffrBlockSize, Integer pOffrOffsetSize, Set<String> pOffrFieldsApiSet,
                                         String pOffrSortExpression, String pOffrSortDirection)
    {
        if(pOpportunityId <> null && pOpportunityId <> '')
        {
            //offrLst.clear();
            String offrQueryStr = '';
            offrFieldsString = MCAUtility.getStringfromSet(pOffrFieldsApiSet, null);

            offrQueryStr = 'Select Opportunity__c, Submission__c, Submission__r.Program__c, Submission__r.Funder__c, ' 
                           +offrFieldsString+
                            ' From Offer__c Where Opportunity__c =:pOpportunityId ORDER BY '+pOffrSortExpression+' '+pOffrSortDirection+' NULLS LAST LIMIT '
                            +pOffrBlockSize+' Offset ' +pOffrOffsetSize;
            return database.query(offrQueryStr);
        }
        return new List<Offer__c>();
    }

    // method to get the wrapper list
    public List<OfferWrapper> getOffrWrapperLst()
    {
         if(offrFirstRun)
        {
            offrWrapperLst = new List<OfferWrapper>();
        }
        if(offrLst<> null && offrLst.size() > 0 )
        {
            if(offrFirstRun)
            {
                //offrWrapperLst = new List<OfferWrapper>();
                for (Integer i = 0; i < offrLst.size(); i++)
                {
                    offrWrapperLst.add(new OfferWrapper(offrLst[i], i, offrEditAllFlag,
                        offrLst[i].Submission__c));
                }
                // moved inside if condition for getting aggregate results only if firstrun is true
                getOfferFieldSum(offrAggregateQueryStr);
                offrFirstRun = false;
            }
        }
        return offrWrapperLst;
    }

    // method to build a map from a list from DB
    public Map<Id, Offer__c> getOfferMapFromList(List<Offer__c> pOffrLst)
    {
        offrFromDbMap.clear();
        for(Offer__c offrInstance :pOffrLst)
        {
            offrFromDbMap.put(offrInstance.Id, offrInstance);
        }
        return offrFromDbMap;
    }

    // method to create new offrables
    public void newOffer()
    {
        globalMap = GRIDOnloadStaticVariable.getGlobalMap();
        customMetaDataSettingMap = GRIDOnloadStaticVariable.getCustomMetaDataMap();
        Schema.DescribeSObjectResult offerDescbResult = globalMap.get(customMetaDataSettingMap.get('Offers').Object_API_Name__c).getDescribe();
        offrIsNewBtnPress = true;
        if(!offrEditAll) {
            saveOffers();
        } else {
            offrSingleErrorOnSave = false;
        }
        offrIsNewBtnPress = false;

        if(!offrSingleErrorOnSave) {
            // to add new record only on first page
            if(offrOffsetsize <> 0) {
                offrOffsetsize = 0;
                beginningOffers();
            }

            offrSubmissionOptions = getSubmissionsPickListVal();
            Offer__c offrNew = new Offer__c();
            DefaultValueHelper.populateValues(offrNew, offrFieldsetList, offerDescbResult);
            offrNew.Opportunity__c = opportunityId;
            offrNew.Send__c = true;

            /*need to add at 0th index if list size > 0 else simple add will work*/
            if(offrWrapperLst.size() > 0 && offrLst.size() > 0) {
                offrWrapperLst.add(0,new OfferWrapper(offrNew, null, true,offrWrapperLst[0].offrSubmissionValue));
                //offrWrapperLst.add(0,new OfferWrapper(offrNew, null, true, offrSubmissionOptions[0].getLabel()));
                offrLst.add(0,offrNew);
            } else {
                offrWrapperLst.add(new OfferWrapper(offrNew, null, true, offrNew.Submission__c));
                offrLst.add(offrNew);
            }
                // reindexing
            for(Integer i=0; i<offrWrapperLst.size(); i++) {
                offrWrapperLst[i].offrIndex = i;
            }
        }
    }

    // method to delete offrables
    public void deleteOffer()
    {
        if(offrWrapperLst[offrIndexToRemove].offr.Id != null)
         {
            try
            {
                delete offrWrapperLst[offrIndexToRemove].offr;
            }
            catch(Exception e)
            {
                ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Info,MCAExceptionHandlerUtility.getErrorMessage(e)));
            }
         }
         offrLst.remove(offrIndexToRemove);
         offrWrapperLst.remove(offrIndexToRemove);

          //re-indexing
             for(Integer i=0;i<offrWrapperLst.size();i++)
             {
               offrWrapperLst[i].offrIndex = i;
             }

        if(offrWrapperLst.size() <= 0)
        {
            refreshOffers();
        }
        getOfferFieldSum(offrAggregateQueryStr);
    }

    // method to cave offrable
    public void saveOffers()
    {
        String offrMsgStr = '';
        String offrSuccessMsgStr ='';
        offrSingleErrorOnSave = false;
        Boolean offrIsUpdated = false;
        offrEditAll = false;
        List<Offer__c> offrListToUpdate = new List<Offer__c>();
        Map<Integer, Integer> offrErrorToWraperIndexMap = new map<Integer, Integer>();
        List<Offer__c> offrTempLst = getOfferFromDB(
            opportunityId,
            offrBlockSize,
            offrOffsetsize,
            offrFieldsApiSet,
            offrSortExpression,
            offrSortDirection
        );
        offrFromDBMap = getOfferMapFromList(offrTempLst);
        for(OfferWrapper offerWraperInstance :offrWrapperLst) {
            Offer__c offrDBObj = offrFromDBMap.get(offerWraperInstance.offr.Id);
            if(offrDBObj != null) {
                offrIsUpdated = false;
                //offrFieldsApiSet.add('Submission__c');
                for(String offrFieldInstance :offrFieldsApiSet) {
                    if(!offrFieldInstance.contains('.Name')) {
                        offrIsUpdated  = offrIsUpdated
                            || (offerWraperInstance.offr.get(offrFieldInstance) != offrDBObj.get(offrFieldInstance))
                            || (offerWraperInstance.offrSubmissionValue != offrDBObj.Submission__c);
                    }
                }
            } else {
                if(!offrIsNewBtnPress) {
                    offrIsUpdated = true;
                }
            }
            if(offrIsUpdated) {
                offerWraperInstance.offr.Submission__c = offerWraperInstance.offrSubmissionValue;
                offrListToUpdate.add(offerWraperInstance.offr);
                offrErrorToWraperIndexMap.put(offrListToUpdate.size()-1, offerWraperInstance.offrIndex);
            }
            offerWraperInstance.offrEdit = offrEditAllFlag;
        }

        try {
            if(offrListToUpdate != null && offrListToUpdate.size() >0) {
                List<Database.upsertResult> results = Database.upsert(offrListToUpdate, false);
                for (Integer i =0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        for (Database.Error err : results[i].getErrors()) {
                             String recordError = err.getMessage();
                            if(!recordError.contains('insufficient access rights on')) {
                                 offrWrapperLst[offrErrorToWraperIndexMap.get(i)].offrEdit = true;
                            }
                            offrSingleErrorOnSave = true;
                            if(results.size() > 1) {
                                offrMsgStr = offrMsgStr 
                                    + 'Error Record '
                                    +(offrErrorToWraperIndexMap.get(i)+1)
                                    +' : '+ recordError + '<br />';
                            } else {
                                offrMsgStr = offrMsgStr 
                                    + 'Error Record '
                                    +(offrErrorToWraperIndexMap.get(i)+1)
                                    +' : '+ recordError ;
                            }
                        }
                    }
                    else if(results[i].isSuccess())
                    {
                        if(offrListToUpdate.size() > 1) {
                            offrSuccessMsgStr = offrSuccessMsgStr
                                + 'Success Record '
                                +(offrErrorToWraperIndexMap.get(i)+1)
                                +' : '+ 'saved successfully!' + '<br />';
                        } else {
                            offrSuccessMsgStr = offrSuccessMsgStr
                                + 'Success Record '
                                +(offrErrorToWraperIndexMap.get(i)+1)
                                +' : '+ 'saved successfully!';
                        }
                        
                        offrWrapperLst[offrErrorToWraperIndexMap.get(i)].offrEdit = offrEditAllFlag;
                    }
                }
                offrSuccessMsgStr = offrSuccessMsgStr.removeEnd('<br />');
                offrMsgStr = offrMsgStr.removeEnd('<br />');
                if(offrSingleErrorOnSave == false && !offrIsNewBtnPress) {
                    offrLst = getOfferFromDB(
                        opportunityId,
                        offrBlockSize,
                        offrOffsetsize,
                        offrFieldsApiSet,
                        offrSortExpression,
                        offrSortDirection
                    );
                    getOfferFieldSum(offrAggregateQueryStr);
                    offrFirstRun = true;
                }

                if(String.isNotBlank(offrMsgStr) || String.isNotBlank(offrSuccessMsgStr)){
                    if(offrPageNavigated) {
                        offrSuccessMsgStr = 'Last changes made by you were saved successfully!';
                    }
                    if(String.isNotBlank(offrMsgStr)) {
                        ApexPages.addMessage(new Apexpages.Message(
                            ApexPages.Severity.Info,offrMsgStr /*+'<br/>'
                            + offrSuccessMsgStr.removeEnd('<br />')*/)
                        );
                        if(String.isNotBlank(offrSuccessMsgStr)) {
                            
                            if(String.isNotBlank(offrSuccessMsgStr)) {
                                ApexPages.addMessage(new Apexpages.Message(
                                    ApexPages.Severity.Info,offrMsgStr +'<br/>'
                                    + offrSuccessMsgStr.removeEnd('<br />'))
                                );
                            } else {
                                ApexPages.addMessage(new Apexpages.Message(
                                    ApexPages.Severity.Info,offrMsgStr)
                                );
                            }
                        }
                    } else {
                        ApexPages.addMessage(new Apexpages.Message(
                            ApexPages.Severity.Info,offrSuccessMsgStr.removeEnd('<br />'))
                        );
                    }
                }
            }
            offrPageNavigated = false;
        }
        catch (Exception e) {
            ApexPages.addMessage(new Apexpages.Message(
                ApexPages.Severity.Info,MCAExceptionHandlerUtility.getErrorMessage(e))
            );
            offrFirstRun = false;
        }
    }

    //method for the first page of list to be displayed
    public void beginningOffers()
    {
        offrPageNavigated = true;
        saveOffers();
        if(!offrSingleErrorOnSave)
        {
            offrOffsetsize = 0;
            offrLst = getOfferFromDB(opportunityId, offrBlockSize, offrOffsetsize, offrFieldsApiSet, offrSortExpression, offrSortDirection);
            offrFirstRun = true;
        }
    }

    //method for previous page of list to be displayed
    public void previousOffers()
    {
        offrPageNavigated = true;
        saveOffers();
        if(!offrSingleErrorOnSave && offrBlockSize <= offrOffsetsize)
        {
            offrOffsetsize = offrOffsetsize - offrBlockSize;
            offrLst = getOfferFromDB(opportunityId, offrBlockSize, offrOffsetsize, offrFieldsApiSet, offrSortExpression, offrSortDirection);
            offrFirstRun = true;
        }
    }

    //method for next page of list to be displayed
    public void nextOffers()
    {
        offrPageNavigated = true;
        saveOffers();
        if(!offrSingleErrorOnSave && offrOffsetsize <= offrRecordCount)
        {
            offrOffsetsize = offrOffsetsize + offrBlockSize;
            offrLst = getOfferFromDB(opportunityId, offrBlockSize, offrOffsetsize, offrFieldsApiSet, offrSortExpression, offrSortDirection);
            offrFirstRun = true;
        }
    }

    //method for last page of list to be displayed
    public void endOffers()
    {
        offrPageNavigated = true;
        saveOffers();
        if(!offrSingleErrorOnSave && math.mod(offrRecordCount , offrBlockSize) == 0){
            offrOffsetsize = offrBlockSize * ((offrRecordCount/offrBlockSize)-1);
        } else if (!offrSingleErrorOnSave && math.mod(offrRecordCount , offrBlockSize) != 0){
            offrOffsetsize = offrBlockSize * ((offrRecordCount/offrBlockSize));
        }
            offrLst = getOfferFromDB(opportunityId, offrBlockSize, offrOffsetsize, offrFieldsApiSet, offrSortExpression, offrSortDirection);
            offrFirstRun = true;
    }

    // method to edit all commissions
    public void editAllOffers()
    {
        offrFirstRun = false;
        offrEditAll = true;
        for(Integer i=0; i< offrWrapperLst.size(); i++)
        {
            offrWrapperLst[i].offrEdit = true;
        }

    }

    // method to refresh
    public void refreshOffers()
    {
        offrLst = getOfferFromDB(opportunityId, offrBlockSize, offrOffsetsize, offrFieldsApiSet, offrSortExpression, offrSortDirection);
        getOfferFieldSum(offrAggregateQueryStr);
        offrFirstRun = true;
    }

    //method to sort list of offers
    public void sortOffers()
    {
            string offrReferenceFieldName = '';
            offrFieldType = Apexpages.currentPage().getParameters().get('offrTypeParam');
            if(offrFieldType.equalsIgnoreCase('REFERENCE'))
            {
                if(offrSortExpression.contains('__c'))
                {
                    offrReferenceFieldName += offrSortExpression.substringBefore('__c')+'__r.Name';
                }
                else
                {
                    offrReferenceFieldName += offrSortExpression.substringBefore('Id')+'.Name';
                }
                offrSortExpression = string.valueOf(offrReferenceFieldName);
            }
            refreshOffers();
    }

    public  List<SelectOption> getSubmissionsPickListVal()
    {
        offrSubmissionOptions.clear();
        offrSubmissionList = [Select Id
                                   , Name
                                   , Funder__r.Name
                                   , Status__c
                                   , Program__r.Name
                                   , CreatedDate
                                From Submission__c
                               Where Opportunity__c =: OpportunityId Order by CreatedDate DESC];
        if(!offrSubmissionList.isempty()) {
            for(Submission__c offrSubmissionObj : offrSubmissionList)
            {
                String subName = offrSubmissionObj.Name;
                offrSubmissionOptions.add(
                    new SelectOption(
                        offrSubmissionObj.Id,
                        offrSubmissionObj.Funder__r.Name+'-'+offrSubmissionObj.Program__r.Name
                    )
                );
            }
        }
        return offrSubmissionOptions;
    }

    @RemoteAction
    global static String getSenderReceipient(Id oppId) {
        Map<String, Schema.SObjectField> schemaOppFieldMap = Schema.SObjectType.Opportunity.fields.getMap();
        Set<String> offerFieldsSet = new Set<String>{
            'Owner_1__c', 'ISO__c', 'ISO_Sales_Rep__c','Owner_1__r.Email', 'ISO__r.Email__c' ,
            'ISO_Sales_Rep__r.Email', 'Owner_1__r.Name', 'ISO__r.Name', 'ISO_Sales_Rep__r.Name'
        };
        FO_Email_Settings__c offersCustmStng = FO_Email_Settings__c.getValues('Email Offers');
        String replyToField  = offersCustmStng.Reply_to_Address__c;
        String sendersNameField = offersCustmStng.Sender_s_Name__c;
        String queryString = 'SELECT Id ';

        if(schemaOppFieldMap.containsKey(replyToField) &&
            !offerFieldsSet.contains(replyToField)) {
            queryString += ', '+offersCustmStng.Reply_to_Address__c;
        }
        
        if(schemaOppFieldMap.containsKey(sendersNameField)&&
            !offerFieldsSet.contains(sendersNameField)) {
            queryString += ', '+offersCustmStng.Sender_s_Name__c;
        }
        for(String offerFields : offerFieldsSet) {
            queryString += ', '+offerFields;
        }
        queryString +=' FROM Opportunity WHERE Id =: oppId';
        Opportunity opportunity = Database.query(queryString);
        EmailConfig emailCnfg = new EmailConfig();
        //emailCnfg.populateData(offersCustmStng, opportunity);
        return emailCnfg.populateData(offersCustmStng, opportunity);
    }

    // wrapper for offers
    public class OfferWrapper
    {
        public Offer__c offr                                                             {get; set;}
        public Integer offrIndex                                                         {get; set;}
        public Boolean offrEdit                                                          {get; set;}
        public String offrSubmissionValue                                                {get; set;}
        public OfferWrapper(Offer__c offrInstance, Integer pOffrIndex, Boolean pOffrEdit,
                             String pOffrSubmissionValue)
        {
            offr = offrInstance;
            offrIndex = pOffrIndex;
            offrEdit = pOffrEdit;
            offrSubmissionValue = pOffrSubmissionValue;
        }
    }
}