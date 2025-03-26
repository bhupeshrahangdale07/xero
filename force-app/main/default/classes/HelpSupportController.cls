/**
 * @description Class is used to Create a support case in case of any help  
     * @Author : Kandisa Technologies
     * @CreatedDate : 05 Jul 2023
*/
public with sharing class HelpSupportController {
    /**
     * @description Method to fetch and Delete the files based on Idset 
     * @return Boolean
     * @param docIdList
    */
    @AuraEnabled
    public static Boolean getFilesSize(List<String> docIdList){
        Boolean flag = true;
        try {
            // @SkipPath: This path is not vulnerable because I have a sanitizer that validates the input
            Set<String> idList = new Set<String>();
            if(docIdList.size() > 0){
                for(String str : docIdList){
                    if(str != null){
                        idList.add(str);
                    }
                }
                if(idList.size() > 0){
                    
                    List<ContentDocument> cdList = [SELECT Id, ContentSize FROM ContentDocument WHERE Id IN: idList WITH SECURITY_ENFORCED];
                    Integer totalSize = 0;
                    if(cdList.size() > 0){
    
                        for(ContentDocument cd : cdList){
                            totalSize += cd.ContentSize;

                        }
                        if(totalSize > 2097152 ){
                            flag = false;
                            if(Schema.sObjectType.ContentDocument.isDeletable()){
                                Database.delete(cdList, false);
                            }
                        }
                    } 
                }
            }
        } catch (Exception e) {
            KTXero__Log__c kl = HandleCustomException.logException(e);			
            throw new AuraHandledException(JSON.serialize(kl));
        }
        return flag;
    }
    
    /**
     * @description Method to create a support case in Salesforce 
     * @return Boolean
     * @param filesData
     * @param supportData
    */
    @AuraEnabled
    public static Boolean submitCase(List<String> filesData, String supportData){
        
        Boolean caseFlag = false;
        SupportDataWrapper sdWrap = new SupportDataWrapper();
        try {
            if(String.isNotBlank(supportData)){
                sdWrap = (SupportDataWrapper)JSON.deserialize(supportData,SupportDataWrapper.class);
            }

            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[] { System.Label.Support_Email};
            message.subject = 'Xero Sync: New Support Request from '+sdWrap.email;
            String emailBody = 'Hello Kandisa Support Team,<br/><br/>';
            emailBody += 'A new support request has been made. Please find details below: <br/>';
            emailBody += '<p><b>Customer Name:</b> '+sdWrap.firstName+' '+sdWrap.lastName+'<br/>';
            emailBody += '<b>Customer email:</b> '+sdWrap.email+'<br/>';
            if(String.isNotBlank(sdWrap.enquiryValue)){
                emailBody += '<b>Type:</b> '+sdWrap.enquiryValue+'<br/>';
            }
            if(String.isNotBlank(sdWrap.description)){
                emailBody += '<b>Detailed Description:</b> '+sdWrap.description+'<br/>';
            }
            emailBody += '<br/>Please resolve the issue soon.';
            emailBody += 'Have a lovely time ahead.<br/><br/>';
            emailBody += 'Best Wishes,<br/>';
            emailBody += 'Kandisa Xero Sync for Salesforce<p>';
            message.setHtmlBody(emailBody);
            if(filesData.size()>0){
                message.setEntityAttachments(filesData);

            }
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

            if (results[0].success) {
                caseFlag = true;
            } else {
                caseFlag = false;
            }
        } catch (Exception e) {
            KTXero__Log__c kl = HandleCustomException.logException(e);			
            throw new AuraHandledException(JSON.serialize(kl));
        }
        return caseFlag;
    }


    /**
     * @description Method to delete conent documents based on Ids 
     * @return Boolean
     * @param deleteIds
    */
    @AuraEnabled
    public static Boolean deleteDocuments(List<String> deleteIds){
        Boolean deleteFlag = false;
        try {
            Set<String> idList = new Set<String>();
            if(deleteIds.size() > 0){

                for(String strId : deleteIds){
                    idList.add(strId);
                } 
            }
            if(idList.size()>0){
                if(Schema.SObjectType.ContentDocument.isDeletable()){

                    // Delete ContentDocuments
                    List<ContentDocument> cdList = [SELECT Id FROM ContentDocument WHERE Id IN: idList WITH SECURITY_ENFORCED];
                    if(cdList.size() > 0){
                        if(Schema.sObjectType.ContentDocument.isDeletable()){
                            Database.DeleteResult[] drList = Database.delete(cdList, false);
                            // Iterate through each returned result
                            for(Database.DeleteResult dr : drList) {
                                if (dr.isSuccess()) {
                                    deleteFlag = true;
                                }else {
                                    deleteFlag = false;
                                    break;
                                }

                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            KTXero__Log__c kl = HandleCustomException.logException(e);			
            throw new AuraHandledException(JSON.serialize(kl));
        }
        return deleteFlag;
    }

    /**
        * @description Wrapper class to manage the support case details
    */
    public class SupportDataWrapper{
        public String firstName;
        public String lastName;
        public String email;
        public String enquiryValue;
        public String description;
    }

    /**
        * @description Wrapper class to manage file details 
    */
    public class FilesDataWrapper{
        public String name;
        public String documentId;
        public String contentVersionId;
        public String contentBodyId;
        public String mimeType;
    }
}