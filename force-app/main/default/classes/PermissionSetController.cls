/**
@Author : Kandisa Technologies
@description : This class contains method for fetching Permission Set to display the values on Permission Set Assignment Component
*/
public with sharing class PermissionSetController {

    /**
     * @description Method to get Permission Set Records
     * @return List<PermissionWrapper> 
    */
    @AuraEnabled
    public static List<PermissionWrapper> fetchPermissionSets(){
        List<PermissionWrapper> permissionWrapList = new List<PermissionWrapper>();
        try{
            List<PermissionSetAssignment> perassign = [SELECT 
                                                        Id, PermissionSetId, PermissionSet.Name, PermissionSet.ProfileId, PermissionSet.Label, 
                                                        PermissionSet.Profile.Name, AssigneeId, Assignee.Name, Assignee.IsActive, Assignee.userName,
                                                        Assignee.email  
                                                        FROM PermissionSetAssignment 
                                                        WHERE PermissionSet.Name IN ('Xero_Integration_User_Read_Only','Xero_Integration_Operational','Xero_Integration_Admin') WITH SECURITY_ENFORCED];
            
            Set<Id> userIdSet = new Set<Id>();
            Map<Id,user> userMap = new Map<Id,User>();

            for(PermissionSetAssignment obj : perassign){
                userIdSet.add(obj.AssigneeId);
                PermissionWrapper wrapObj = new PermissionWrapper();
                wrapObj.userId = obj.AssigneeId;
                wrapObj.name = obj.Assignee.Name;
                wrapObj.username = obj.Assignee.username;
                wrapObj.email = obj.Assignee.email;
                wrapObj.IsActive = obj.Assignee.IsActive;
                wrapObj.permissionSetName = obj.PermissionSet.Name;
                wrapObj.permissionSetLabel= obj.PermissionSet.Label;
                permissionWrapList.add(wrapObj);
            }

            if(userIdSet.size() > 0){
                userMap = new Map<Id,User>([SELECT Id,Name,Username,Email,ProfileId,profile.Name, IsActive FROM User WHERE Id IN: userIdSet WITH SECURITY_ENFORCED]);
                for(PermissionWrapper obj : permissionWrapList){
                    if(userMap.containsKey(obj.userId)){
                        obj.profile = userMap.get(obj.userId).profile.Name;
                    }
                }
            }
        } catch (Exception e) {
            KTXero__Log__c logObj = HandleCustomException.logException(e);
            throw new AuraHandledException(JSON.serialize(logObj));
        }
        return permissionWrapList;
    }
    /**
     * @description Wrapper class for Permission Sets
    */
    public class PermissionWrapper{
        /**
         * @description This variable will hold value of AssigneeId from PermissionSetAssignment Record
        */
        @AuraEnabled public String userId {get;set;}
        /**
         * @description This variable will hold value of Assignee.Name from PermissionSetAssignment Record
        */
        @AuraEnabled public String name {get;set;}
        /**
         * @description This variable will hold value of Assignee.username from PermissionSetAssignment Record
        */
        @AuraEnabled public String userName {get;set;}
        /**
         * @description This variable will hold value of Assignee.email from PermissionSetAssignment Record
        */
        @AuraEnabled public String email {get;set;}
        /**
         * @description This variable will hold value of User's profile.Name from User Record
        */
        @AuraEnabled public String profile {get;set;} 
        /**
         * @description This variable will hold value of Assignee.IsActive from PermissionSetAssignment Record
        */
        @AuraEnabled public Boolean isActive {get;set;} 
        /**
         * @description This variable will hold value of PermissionSet.Name from PermissionSetAssignment Record
        */
        @AuraEnabled public String permissionSetName {get;set;}
        /**
         * @description This variable will hold value of PermissionSet.Label from PermissionSetAssignment Record
        */
        @AuraEnabled public String permissionSetLabel {get;set;}
    }
}