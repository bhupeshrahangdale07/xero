/**
     * @description Class to manage logs after all the callouts happend to Xero
     * @Author : Kandisa Technologies
     * @CreatedDate : 10 March 2023
*/
public with sharing class TroubleshootingController {

    @AuraEnabled
    /**
     * @description Method to fetch the logs stored in salesforce
     * @return List<LogDataWrapper>
    */
    public static List<LogDataWrapper> getLogData(){
        List<Log__c> logList = new List<Log__c>();
        List<LogDataWrapper> logDataWrapList = new List<LogDataWrapper>(); 
        try{
            logList = [SELECT Id, Name, Request_Endpoint__c, Request_Method__c, Request_Body__c, Response_Status_Code__c, Response_body__c, Response_Status__c, CreatedDate FROM Log__c WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC];
            if(logList.size()>0){
                for(Log__c l : logList){
                    LogDataWrapper ldw = new LogDataWrapper();
                    ldw.id = l.Id;
                    ldw.name = l.Name;
                    ldw.nameUrl = '/'+l.Id;

                    if(String.isNotBlank(l.Request_Endpoint__c)){

                        if(l.Request_Endpoint__c.contains('connections')){
                            String entity = l.Request_Endpoint__c;
                            entity = entity.substringAfter('api.xro/');
                            entity = entity.substringAfter('/');
                            entity = entity.substringBefore('/');
                            ldw.requestEndpoint = entity;
                        }else if(l.Request_Endpoint__c.contains('token')){
                            ldw.requestEndpoint = 'token';
                        }else{
                            ldw.requestEndpoint = 'connections';
                        }
                    }
                    
                    ldw.requestMethod = l.Request_Method__c;
                    ldw.requestBody = l.Request_Body__c;
                    ldw.responseStatusCode = l.Response_Status_Code__c;
                    ldw.responseBody = l.Response_body__c;
                    ldw.responseStatus = l.Response_Status__c;
                    ldw.createdDate = date.newinstance(l.CreatedDate.year(), l.CreatedDate.month(), l.CreatedDate.day());
                    logDataWrapList.add(ldw);
                }
            }
        }catch(exception e){
            // String errorMsg = 'The following exception has occurred: ' + e.getMessage();
            // HandleCustomException.logException(e);
            // throw new AuraHandledException(errorMsg);
            KTXero__Log__c kl = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(kl));
        }
        return logDataWrapList;
    }

    /**
     * @description Method to fetch setup configuration data
     * @return SetupWrapper
    */
    @AuraEnabled
    public static SetupWrapper getSetupConfiguration(){
        SetupWrapper sw = new SetupWrapper();
        KTXero__Setup_Configurations__c sc = new KTXero__Setup_Configurations__c();
        try {
            sc = [SELECT Id, Name, Delete_Logs__c FROM KTXero__Setup_Configurations__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED];
            sw.id = sc.Id; 
            sw.deleteLog = sc.Delete_Logs__c;
        } catch (Exception e) {
            KTXero__Log__c kl = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(kl));
        }
        return sw;
    }

    /**
     * @description Method to update KTXero__Setup_Configurations__c as well as schedule a new job
     * @return Boolean
     * @param configData
     * @param scheduleJobId
    */
    @AuraEnabled
    public static Boolean updateLogConfig(String configData, String scheduleJobId){
        Boolean updated = false;
        SetupWrapper sw = new SetupWrapper();
        try {
            if(String.isNotBlank(configData)){
                sw = (SetupWrapper)JSON.deserialize(configData,SetupWrapper.class);
                KTXero__Setup_Configurations__c sc = new KTXero__Setup_Configurations__c();
                sc.Id = sw.id;
                sc.Delete_Logs__c = sw.deleteLog;
                // if(schema.sObjectType.KTXero__Setup_Configurations__c.isUpdateable()){
                    if(sc != null){

                        FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                        List<KTXero__Setup_Configurations__c> scList = new List<KTXero__Setup_Configurations__c>();
                        scList.add(sc);

                        flsWrap = FLSChecker.dmlUpdate(scList);
                        if(!flsWrap.isSuccess){
                            throw new AuraHandledException(flsWrap.message);
                        }else{
                            updated = flsWrap.isSuccess;
                        }
                    }

                    // Database.SaveResult saveResult = Database.update(sc);
                    // updated = saveResult.isSuccess();
                // }

                if(sc.Delete_Logs__c == 'None' && String.isNotBlank(scheduleJobId) && scheduleJobId != null){
                    System.abortJob(scheduleJobId);
                }else{
                    String expression = '';
                    Datetime todayDate = System.now();
                    Integer day = todayDate.day();
                    String dayName = todayDate.formatGMT('EEE').toUpperCase();
                    if(sc.Delete_Logs__c == 'Daily'){
                        expression = '0 0 0 1/1 * ? *';
                    }else if(sc.Delete_Logs__c == 'Weekly'){
                        expression = '0 0 0 ? * '+dayName+' *';
                    }else if(sc.Delete_Logs__c == 'Monthly'){
                        expression = '0 0 0 '+day+' 1/1 ? *';
                    }else if(sc.Delete_Logs__c == '6 Months'){
                        expression = '0 0 0 '+day+' 1/6 ? *';
                    }else if(sc.Delete_Logs__c == 'Yearly'){
                        expression = '0 0 0 '+day+' 1 ? *';
                    }

                    if(scheduleJobId != null && String.isNotBlank(scheduleJobId)){
                        System.abortJob(scheduleJobId);
                    }
                    system.schedule('LogBatchDeleteSchedule',expression, new CalloutLogDeleteBatchJobscheduled());
                }
            }
        } catch (Exception e) {
            
            KTXero__Log__c kl = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(kl));
        }
        return updated;
    }

    /**
     * @description Method to delete all logs
     * @return Boolean
     * @param deleteList
    */
    @AuraEnabled
    public static Boolean deleteAllLogs(List<Id> deleteList){
        Boolean successFlag = false;
        try {
            if(deleteList.size()>0 ){

                List<KTXero__Log__c> logList = [SELECT Id FROM KTXero__Log__c WHERE Id IN : deleteList WITH SECURITY_ENFORCED];

                if(logList.size() > 0){

                    FLSChecker.FLSCheckWrapper flsWrap = new FLSChecker.FLSCheckWrapper();
                    flsWrap = FLSChecker.dmlDelete(logList);
                    if(!flsWrap.isSuccess){
                        throw new AuraHandledException(flsWrap.message);

                    }else{
                        successFlag = true;
                    }
                }
            }
        } catch (Exception e) {
            KTXero__Log__c kl = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(kl));
        }
        return successFlag;
    }

    /**
     * @description Method to fetch Scheduled jobs data
     * @return CronWrapper
     * @param scheduleName
    */
    @AuraEnabled
    public static CronWrapper getScheduleData(String scheduleName){
        CronWrapper cw = new CronWrapper();
        List<CronTrigger> cron = new List<CronTrigger>(); 
        try {
            cron = [SELECT Id, CronJobDetailId, CronJobDetail.Name, CronJobDetail.JobType, 
                    NextFireTime, PreviousFireTime, State, StartTime, EndTime, CronExpression, CreatedDate,
                    TimesTriggered FROM CronTrigger WHERE CronJobDetail.Name =: scheduleName WITH SECURITY_ENFORCED];
            if(cron.size()>0){

                cw.id = cron[0].Id;
                cw.cronjobdetailId = cron[0].CronJobDetailId;
                cw.cronjobName = cron[0].CronJobDetail.Name;
                cw.cronjobType = cron[0].CronJobDetail.JobType;
                cw.state = cron[0].State;
                cw.cronExpression = cron[0].CronExpression;
                cw.timesTriggered = cron[0].TimesTriggered;
                cw.createdDate = cron[0].CreatedDate;
                cw.nextRunTime = cron[0].NextFireTime.format('dd-MM-yyyy h:mm a');
                cw.previousRunTime = cron[0].PreviousFireTime != null ? cron[0].PreviousFireTime.format('dd-MM-yyyy h:mm a') : '---';
                cw.startTime = cron[0].StartTime.format('dd-MM-yyyy h:mm a');
                cw.endTime = cron[0].EndTime;
            }
        }catch (Exception e) {
            KTXero__Log__c kl = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(kl));
        }
        return cw;
    }

    /**
     * @description Class to manage Logs data
     * @Author : Kandisa Technologies 
    */
    public class LogDataWrapper{
        @AuraEnabled public String id ;
        @AuraEnabled public String name ;
        @AuraEnabled public String nameUrl ;
        @AuraEnabled public String requestEndpoint ;
        @AuraEnabled public String requestMethod ;
        @AuraEnabled public String requestBody ;
        @AuraEnabled public Double responseStatusCode ;
        @AuraEnabled public String responseBody ;
        @AuraEnabled public String responseStatus ;
        @AuraEnabled public Date createdDate ;
        
    }
    
    /**
     * @description Class to manage setup data
     * @Author : Kandisa Technologies 
    */
    public class SetupWrapper{
        @AuraEnabled public String id ;
        @AuraEnabled public String deleteLog ;
    }

    
    /**
     * @description Class to manage cron data
     * @Author : Kandisa Technologies 
    */
    public class CronWrapper{           
        @AuraEnabled public String id ;
        @AuraEnabled public String cronjobdetailId ;
        @AuraEnabled public String cronjobName ;
        @AuraEnabled public String cronjobType ;
        @AuraEnabled public String state ;
        @AuraEnabled public String cronExpression ;
        @AuraEnabled public Integer timesTriggered ;
        @AuraEnabled public DateTime createdDate ;
        @AuraEnabled public String nextRunTime ;
        @AuraEnabled public String previousRunTime ;
        @AuraEnabled public String startTime ;
        @AuraEnabled public DateTime endTime ;
    }
}