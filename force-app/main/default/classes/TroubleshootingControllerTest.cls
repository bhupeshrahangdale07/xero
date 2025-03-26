@isTest
public with sharing class TroubleshootingControllerTest {
    
    @isTest
    static void testgetSetupConfig() {
        KTXero__Setup_Configurations__c sc = TestUtil.createSetupCOnfig(true);
        Test.StartTest();
        TroubleshootingController.SetupWrapper sw = TroubleshootingController.getSetupConfiguration();
        System.assertEquals(sw.deleteLog,sc.Delete_Logs__c,'Success');
        Test.StopTest();
    }

    @isTest
    static void testgetLogData() {
        Log__c l = TestUtil.createLog(true);
        List<Id> logList = new List<Id>();
        logList.add(l.Id);
        
        Test.StartTest();
        List<TroubleshootingController.LogDataWrapper> lw = TroubleshootingController.getLogData();
        System.assertEquals(logList.size(),lw.size(),'Success');

        Boolean deleted = TroubleshootingController.deleteAllLogs(logList);
        System.assertEquals(deleted,true,'Success');
        Test.StopTest();
    }
    
    @isTest
    static void testgetScheduleData() {
        String cronexp = '0 0 0 1/1 * ? *';
        Test.startTest();
        String jobId = '';
        jobId = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'LogBatchDeleteSchedule'].Id;
        if(String.isNotBlank(jobId)){
            System.abortJob(jobId);
        }
        String schjobId = System.schedule('LogBatchDeleteSchedule',cronexp, new CalloutLogDeleteBatchJobscheduled());
        TroubleshootingController.CronWrapper scd = TroubleshootingController.getScheduleData('LogBatchDeleteSchedule');
        System.assertEquals(schjobId,String.valueOf(scd.id).substring(0, 15),'Success');
        System.abortJob(schjobId);
        Test.StopTest();
    }
    
    @isTest
    static void testupdateLogConfig() {
        KTXero__Setup_Configurations__c sc = TestUtil.createSetupCOnfig(true);
        TroubleshootingController.SetupWrapper sw = new TroubleshootingController.SetupWrapper();
        sw.id = sc.Id;
        sw.deleteLog = sc.Delete_Logs__c;
        String jobId = '';
        jobId = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'LogBatchDeleteSchedule'].Id;
        if(String.isNotBlank(jobId)){
            System.abortJob(jobId);
        }
        Test.startTest();
        
        Boolean flag = TroubleshootingController.updateLogConfig(JSON.serialize(sw),null);
        System.assertEquals(flag,true,'Success');
        
        Test.StopTest();
    }
    
    @isTest
    static void testupdateLogConfig1() {
        KTXero__Setup_Configurations__c sc = TestUtil.createSetupCOnfig(true);
        TroubleshootingController.SetupWrapper sw = new TroubleshootingController.SetupWrapper();
        sw.id = sc.Id;
        sw.deleteLog = sc.Delete_Logs__c;
        String jobId = '';
        jobId = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'LogBatchDeleteSchedule'].Id;
        if(String.isNotBlank(jobId)){
            System.abortJob(jobId);
        }
        Test.startTest();
        
        String cronexp = '0 0 0 1/1 * ? *';
        String schjobId = System.schedule('LogBatchDeleteSchedule',cronexp, new CalloutLogDeleteBatchJobscheduled());
        
        sw.deleteLog = 'Weekly';
        Boolean flag1 = TroubleshootingController.updateLogConfig(JSON.serialize(sw),schjobId);
        System.assertEquals(flag1,true,'Success');
        
        Test.StopTest();
    }

    @isTest
    static void testupdateLogConfig2() {
        KTXero__Setup_Configurations__c sc = TestUtil.createSetupCOnfig(true);
        TroubleshootingController.SetupWrapper sw = new TroubleshootingController.SetupWrapper();
        sw.id = sc.Id;
        sw.deleteLog = sc.Delete_Logs__c;
        String jobId = '';
        jobId = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'LogBatchDeleteSchedule'].Id;
        if(String.isNotBlank(jobId)){
            System.abortJob(jobId);
        }
        Test.startTest();
        
        String cronexp = '0 0 0 1/1 * ? *';
        String schjobId = System.schedule('LogBatchDeleteSchedule',cronexp, new CalloutLogDeleteBatchJobscheduled());
        
        sw.deleteLog = 'Monthly';
        Boolean flag1 = TroubleshootingController.updateLogConfig(JSON.serialize(sw),schjobId);
        System.assertEquals(flag1,true,'Success');
        
        Test.StopTest();
    }

    @isTest
    static void testupdateLogConfig3() {
        KTXero__Setup_Configurations__c sc = TestUtil.createSetupCOnfig(true);
        TroubleshootingController.SetupWrapper sw = new TroubleshootingController.SetupWrapper();
        sw.id = sc.Id;
        sw.deleteLog = sc.Delete_Logs__c;
        String jobId = '';
        jobId = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'LogBatchDeleteSchedule'].Id;
        if(String.isNotBlank(jobId)){
            System.abortJob(jobId);
        }
        Test.startTest();
        
        String cronexp = '0 0 0 1/1 * ? *';
        String schjobId = System.schedule('LogBatchDeleteSchedule',cronexp, new CalloutLogDeleteBatchJobscheduled());
        
        sw.deleteLog = 'Yearly';
        Boolean flag1 = TroubleshootingController.updateLogConfig(JSON.serialize(sw),schjobId);
        System.assertEquals(flag1,true,'Success');
        
        Test.StopTest();
    }

    @isTest
    static void testupdateLogConfig4() {
        KTXero__Setup_Configurations__c sc = TestUtil.createSetupCOnfig(true);
        TroubleshootingController.SetupWrapper sw = new TroubleshootingController.SetupWrapper();
        sw.id = sc.Id;
        sw.deleteLog = sc.Delete_Logs__c;
        String jobId = '';
        jobId = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'LogBatchDeleteSchedule'].Id;
        if(String.isNotBlank(jobId)){
            System.abortJob(jobId);
        }
        Test.startTest();
        
        String cronexp = '0 0 0 1/1 * ? *';
        String schjobId = System.schedule('LogBatchDeleteSchedule',cronexp, new CalloutLogDeleteBatchJobscheduled());
        
        sw.deleteLog = '6 Months';
        Boolean flag1 = TroubleshootingController.updateLogConfig(JSON.serialize(sw),schjobId);
        System.assertEquals(flag1,true,'Success');
        
        Test.StopTest();
    }
}