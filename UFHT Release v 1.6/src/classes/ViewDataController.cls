/**
 * @Class Name: ViewDataController
 * @Description: This is the main controller for ViewData page.
 *               It sets the filter options in the top section of the page.
 *==================================================================================================
 *       Version   | Date        | Author             | Comments
 *--------------------------------------------------------------------------------------------------
 *       1.0       | 04/07/2016  | Eternus Solutions   | 1. Created the class for above functionality.
 *===================================================================================================
 **/
 
public with sharing class ViewDataController {

    // Holds a list of options for the date filter
    public list<SelectOption> dateFilterSelectOptionsList { get; set; }

    // String to hold the date format according to logged in user's locale
    public String dateFormat { get; set; }

    // Instance for keeping track of end date selected in filters.
    public Ultra_Track_Container__c endDateObj { get; set; }

    // Holds the end date selected by user on the page.
    public String endDate { get; set; }

    // Integer varible to hold number fields to display on single page.
    public Integer lastNumberOfDays { get; set; }

    // Holds a list of objects for which field history tracking is set up.
    public list<SelectOption> objectSelectedOptionsList { get; set; }

    // Holds the number of records to display on the page.
    public Integer pageSize { get; set; }

    // Holds the base URL for current salesforce instance (necessary for callouts)
    public String salesforceBaseUrl { get; set; }

    // Holds the Ultra Track Container Id for the selected object.
    public String selectedObject { get; set; }

    // Holds the type of the filter selected for date.
    public String selectedDateFilter { get; set; }

    // Holds the start date selected by user on the page.
    public String startDate { get; set; }

    // Instance for keeping track of start date selected in filters.
    public Ultra_Track_Container__c startDateObj { get; set; }

    // Boolean to check if it is necessary to show the User filter list.
    public Boolean isAllDataAccessible { get; set; }
    
    // string to hold the record in from the component
    public String recordId { get; set; }
    
    // Boolean to check if component is being shown in Related list or view data page
    public Boolean isRelatedList { get; set; } 
    
    public String parentObjName { get; set; }
    
    public String objParam { get; set; }
    
    public String recordParam { get; set; }
    
    public Id objectSelectedContainerId { get; set; }
    
    public String objectName { get;set;}
    public boolean isValidLicense {get;set;}
    public String licenseMessages {get;set;}
    /**
     * @Author: Eternus Solutions
     * @Description: Fetch and set the data for the each variables and call the TrackObject,
     *               Datefilter, DateFormat methods
     * @Param:
     * @Return:
     * @Date: 15/11/2015
     **/
    public ViewDataController() {
        dateFilterSelectOptionsList = new list<SelectOption>();
        isRelatedList = false;
        startDateObj = new Ultra_Track_Container__c();
        endDateObj = new Ultra_Track_Container__c();
        isValidLicense = LMSConfigManager.getIfLicenseValid(); 
        licenseMessages = getNotificationMessage();
        startDate = '';
        endDate = '';
        objParam = '';
        //Check whether the user has access for update access on Ultra Track Container
        if(UltraTrackUtility.checkObjectAndFieldLevelSecurity('UFHT__Ultra_Track_Container__c', 
                                                        new list<String> {'UFHT__DateHolder__c'},
                                                        'isUpdate')){
            if(string.valueOf(ApexPages.currentPage()).contains('id')) {
                recordParam = ApexPages.currentPage().getParameters().get('id');
            }
            else  if(string.valueOf(ApexPages.currentPage()).contains('rec')) {
                recordParam = ApexPages.currentPage().getParameters().get('rec');
            }
            isRelatedList = ApexPages.currentPage().getParameters().get('inline') == '1' ? true:false;
            if(!String.isBlank(recordParam) && recordParam != null) {
                objectSelectedContainerId = UltraTrackUtility.getContainerRecordIdForObj(UltraTrackUtility.getObjectNameFromPrefix(recordParam.substring(0,3)));
                objectName = UltraTrackUtility.getObjectNameFromPrefix(recordParam.substring(0,3));
            }
        }

        lastNumberOfDays = 30;
        isAllDataAccessible = false;
        salesforceBaseUrl = UFHTConstants.EMPTY_STRING;
        String getSalesforceBaseURL;
        selectedDateFilter = UFHTConstants.CUSTOM;
        map<String,Configuration__c> configMap = new  map<String,Configuration__c>();
        if(UltraTrackUtility.isAllowDMLForCustomSetting('UFHT__Configuration__c','isAccessible')){
            configMap = Configuration__c.getAll();
        }
        getSalesforceBaseURL = configMap.containsKey(UFHTConstants.CONFIGURATION_SETTING_NAME)
                             ? configMap.get(UFHTConstants.CONFIGURATION_SETTING_NAME).SalesforceBaseURL__c
                             : Url.getSalesforceBaseUrl().getHost();

        if( configMap.containsKey(UFHTConstants.CONFIGURATION_SETTING_NAME) && String.isNotBlank(getSalesforceBaseURL) ) {
            salesforceBaseUrl = UFHTConstants.PROTOCOL + getSalesforceBaseURL;
        }
        View_Field_History_Sharing_Setting__c viewDataSharingObj;
        if(UltraTrackUtility.isAllowDMLForCustomSetting('UFHT__View_Field_History_Sharing_Setting__c','isAccessible')){
            viewDataSharingObj = View_Field_History_Sharing_Setting__c.getInstance( UserInfo.getProfileId() );
        }
        isAllDataAccessible = (viewDataSharingObj != null
                              && viewDataSharingObj.View_All_Data__c != null
                              && viewDataSharingObj.View_All_Data__c);

        if(Integer.valueOf(System.Label.VD_Number_Of_Records_Per_Page) > 0) {
            pageSize = Integer.valueOf(System.Label.VD_Number_Of_Records_Per_Page);
        }
        else {
            pageSize = 25;
        }
        getDateFilters();
        // get all Objects of which history tracking is enabled in a sorted order
        objectSelectedOptionsList = UltraTrackUtility.getTrackedObjects();
        
        // if url containd record id
        if(recordParam != '' && recordParam != null ) {
            selectedObject = objectSelectedContainerId;
        }
        // else url does not contain record id
        else {
            selectedObject = objectSelectedOptionsList[0].getValue();
        }
        //selectedDateFilter = UFHTConstants.SELECT_DATE_RANGE_OPTION_LABEL;
        selectedDateFilter = dateFilterSelectOptionsList[0].getValue();
        dateFilter();
        getDateFormat();
    }

    // Message to compile the reminder notification for package
    private String getNotificationMessage() {
        Feature_Installation_Master__c installDetails = LMSConfigManager.getFeatureDetails(LMSConstants.FEATURE_FHT);
    
        if (installDetails == null) {
            return LMSConstants.MSG_INVALID_LICENSE;
        }
        
        String message;
    
        String reminderMessage = LMSConstants.MSG_PACKAGE_RENEWAL_REMINDER;
        String expiredMessage = LMSConstants.MSG_PACKAGE_EXPIRED;
        String suspendedMessage = LMSConstants.MSG_PACKAGE_SUSPENDED;
    
        // Check for suspended package
        if (installDetails.Is_Active__c == false && installDetails.License_Days_Remaining__c == -1) {
            return suspendedMessage;
        }
    
        // If yes, then check if the remaining days is less than 15
        if (installDetails.License_Days_Remaining__c <= 15) {
            // Check if it is equal to zero
            if (installDetails.License_Days_Remaining__c == 0) {
                // If yes, then add the expired message
                message = expiredMessage;
            } else {
                // else add the less than 15 days message
                message = reminderMessage.replace('DATEREMAINING', '' + installDetails.License_Days_Remaining__c);
            }
        }
        
        if (!String.isBlank(message)) {
           return message;
        }
        
        if (!LMSConfigManager.getIfLicenseValid()) {
           return LMSConstants.MSG_INVALID_LICENSE;
        }
        
        return null;
    }

    //Check License information for renewal 
    public void renewalLicenseCheck() {
        LmaCommunicationManager.LicenseInformation renewalInfo;
        renewalInfo = LicenseCheckScheduler.renewal();
        if(renewalInfo != null && renewalInfo.isValid == true) {
           licenseMessages = getNotificationMessage();
        }
    }

    /**
     * @Author: Eternus Solutions
     * @Description:  Method to get dateFilters from custom setting to display on page.
     * @Param:
     * @Return:
     * @Date: 15/11/2015
     **/
    public void getDateFilters() {
        list<DateFilterWrapper> dateFilterWrapperList = new list<DateFilterWrapper>();
        if(!UltraTrackUtility.isAllowDMLForCustomSetting('UFHT__View_Field_History_Date_Filters__c','isAccessible')){
            UltraTrackUtility.displayMessage(ApexPages.Severity.ERROR, System.Label.GenericError);
            return;
        }
        
        for( View_Field_History_Date_Filters__c dateFilterObj : View_Field_History_Date_Filters__c.getAll().values() ) {
            dateFilterWrapperList.add( new DateFilterWrapper(Integer.valueOf(dateFilterObj.Sr_No__c), dateFilterObj.name) );
        }
        dateFilterSelectOptionsList.add( new SelectOption(UFHTConstants.WHITE_SPACE,
                                                                  UFHTConstants.SELECT_DATE_RANGE_OPTION_LABEL,
                                                                  true
                                                                  ) );
        if(!dateFilterWrapperList.isEmpty() &&
           dateFilterSelectOptionsList != null) {
            dateFilterWrapperList.sort();
            
            for(DateFilterWrapper dateFilter : dateFilterWrapperList) {
                dateFilterSelectOptionsList.add( new SelectOption(dateFilter.name,
                                                                  dateFilter.name
                                                                  ) );
            }
        }
    }

    /**
     * @Author: Eternus Solutions
     * @Description: Method to get start and end date for selected date filter.
     * @Param:
     * @Return:
     * @Date: 15/11/2015
     **/
    public void dateFilter() {
        list<Ultra_Track_Container__c> startEndDateList = new list<Ultra_Track_Container__c>();
        //Check whether the user has access for update access on Ultra Track Container
        if(!UltraTrackUtility.checkObjectAndFieldLevelSecurity('UFHT__Ultra_Track_Container__c', 
                                                               new list<String> {'UFHT__DateHolder__c'},
                                                               'isUpdate')){
                UltraTrackUtility.displayMessage(ApexPages.severity.WARNING, UFHTConstants.WHITE_SPACE + System.Label.GenericError);
                return;
        }
        if( String.isNotBlank(selectedDateFilter) && !selectedDateFilter.equalsIgnoreCase(UFHTConstants.CUSTOM)  && !selectedDateFilter.equalsIgnoreCase(UFHTConstants.DATE_FILTER_LAST_N_DAYS) ) {
            startEndDateList = UltraTrackUtility.getStartAndEndDateForFilter(selectedDateFilter);
            if(startEndDateList != null &&
               startEndDateList.size() > 1) {
                startDateObj.DateHolder__c = startEndDateList[0].DateHolder__c;
                endDateObj.DateHolder__c = startEndDateList[1].DateHolder__c;
            }
        }
        else if(selectedDateFilter == UFHTConstants.DATE_FILTER_LAST_N_DAYS) {
            if(lastNumberOfDays != null) {
                startDateObj.DateHolder__c = Date.Today().addDays(-lastNumberOfDays);
            }
            endDateObj.DateHolder__c = Date.Today();
        }
        if(startDateObj.DateHolder__c != null) {
            startDate = startDateObj.DateHolder__c.format();
        }
        else {
            startDate = null;
        }
        if(endDateObj.DateHolder__c != null) {
            endDate = endDateObj.DateHolder__c.format();
        }
        else {
            endDate = null;
        }
    }

    /**
     * @Author: Eternus Solutions
     * @Description: Method to get date format according to logged in user's locale.
     * @Param:
     * @Return:
     * @Date: 13/07/2016
     **/
    public void getDateFormat() {
        dateFormat = UFHTConstants.EMPTY_STRING;
        String stringifiedDate = Date.newInstance(1970, 9, 13).format();
        Boolean isDotReplaced = false;
        Integer indexOfDot = stringifiedDate.indexOf(UFHTConstants.DOT_OPERATOR);
        list<Integer> charList = stringifiedDate.getChars();

        while(indexOfDot != -1) {
            isDotReplaced = true;
            charList[indexOfDot] = UFHTConstants.DATE_SEPARATOR_SLASH.getChars()[0];
            stringifiedDate = String.fromCharArray(charList);
            indexOfDot = stringifiedDate.indexOf(UFHTConstants.DOT_OPERATOR);
        }

        String dateSeparator = stringifiedDate.replaceAll(UFHTConstants.REGEX_FOR_DIGIT, UFHTConstants.EMPTY_STRING).substring(0,1);

        for( String placeHolder : stringifiedDate.split(dateSeparator) ) {
            if(placeHolder.indexOf( String.valueOf(1970) ) != -1) {
                dateFormat += String.isBlank(dateFormat) ? UFHTConstants.DATE_FORMAT_YEAR : dateSeparator + UFHTConstants.DATE_FORMAT_YEAR;
            } else if(placeHolder.indexOf( String.valueOf(9) ) != -1) {
                dateFormat += String.isBlank(dateFormat) ? UFHTConstants.DATE_FORMAT_MONTH : dateSeparator + UFHTConstants.DATE_FORMAT_MONTH;
            } else if(placeHolder.indexOf( String.valueOf(13) ) != -1) {
                dateFormat += String.isBlank(dateFormat) ? UFHTConstants.DATE_FORMAT_DAY : dateSeparator + UFHTConstants.DATE_FORMAT_DAY;
            }
        }

        if(isDotReplaced) {
            indexOfDot = dateFormat.indexOf(UFHTConstants.DATE_SEPARATOR_SLASH);
            charList = dateFormat.getChars();
            while(indexOfDot != -1) {
                charList[indexOfDot] = UFHTConstants.DOT_OPERATOR.getChars()[0];
                dateFormat = String.fromCharArray(charList);
                indexOfDot = dateFormat.indexOf(UFHTConstants.DATE_SEPARATOR_SLASH);
            }
        }
    }
}