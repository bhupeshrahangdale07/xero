/**
     * @description Class to check FLS and object permissions for CRUD operations
     * @Author : Kandisa Technologies
     * @CreatedDate : 10 Oct 2023
*/
public with sharing class FLSChecker {
    
    /**
     * @description to check create permissions for list of Sobjects 
     * @return FLSCheckWrapper
     * @param objList
    */
    public static FLSCheckWrapper dmlInsert(List<SObject> objList){
        FLSCheckWrapper fl = new FLSCheckWrapper();
        
        if (objList == null || objList.isEmpty()){
            fl.isSuccess = false;
            fl.message = 'No data found.';
            return fl;
        }
        SObjectType myType = objList[0].getSObjectType();
        if (myType.getDescribe().isCreateable() == false) {
            fl.isSuccess = false;
            fl.message = 'Insufficient access for '+myType +'creation';
            return fl;
        }

        FLSCheckWrapper flsNew = new FLSCheck('insert').check(objList, myType);
        if(flsNew.isSuccess){
            Database.SaveResult[] sRList = Database.insert(objList);
            for(Database.SaveResult sr : sRList){
                if(sr.isSuccess()){
                    fl.isSuccess = true;
                    fl.message = 'Everything is working Fine';
                }else{
                    // Operation failed, so get all errors                
            
                    fl.isSuccess = false;
                    fl.message = 'Something went wrong.';
                    break;
                }
            }
            
        }else{
            fl.isSuccess = false;
            fl.message = flsNew.message;
        }

        return fl;
    }

    /**
     * @description to check read permissions for list of fields and Sobjects 
     * @return FLSCheckWrapper
     * @param fieldMap
    */
    public static FLSCheckWrapper accessibleCheck(Map<String,List<String>> fieldMap){
        FLSCheckWrapper fl = new FLSCheckWrapper();
        fl.isSuccess = true;
        fl.message = '';
        Set<String> fieldList = new Set<String>();

        if(fieldMap == null || fieldMap.size() <= 0){
            fl.isSuccess = false;
            fl.message = 'No data found.';
            return fl;
        }

        for(String str : fieldMap.keySet()){
            SObjectType objType = Schema.getGlobalDescribe().get(str);
            if (objType.getDescribe().isAccessible() == false) {
                fl.isSuccess = false;
                fl.message = 'Insufficient access '+objType;
                return fl;
            }else{
                Map<String, Schema.SObjectField> sobjfieldMap = objType.getDescribe().fields.getMap();
                
                for(String fieldName : fieldMap.get(str)){
                    if(fieldName == 'Id'){
                        continue;
                    }
                    if (fieldName == 'Geolocation__c'){
                        continue;
                    }
    
                    Schema.SObjectField myField = sobjfieldMap.get(fieldName);
    
                    if (myField == null){
                        continue;
                    }
    
                    if (myField.getDescribe().isAccessible() == false) {
                        fieldList.add(myField+' | '+objType);
                        continue;
                    }
                }
            }
        }

        if(fieldList.size() > 0){
            String fieldStr = '';
            for(String str : fieldList){
                fieldStr += str+', ';
            }
            fieldStr = fieldStr.removeEnd(', ');
            fl.isSuccess = false;
            fl.message = 'Insufficient access for '+fieldStr; 
        }
        return fl;
    }

    /**
     * @description method to check upsert permissions for list of Sobjects 
     * @return FLSCheckWrapper
     * @param objList
    */
    public static FLSCheckWrapper dmlUpsert(List<SObject> objList){
        FLSCheckWrapper fl = new FLSCheckWrapper();
        
        if (objList == null || objList.isEmpty()){
            fl.isSuccess = false;
            fl.message = 'No data found.';
            return fl;

        }
        SObjectType myType = objList[0].getSObjectType();

        if (myType.getDescribe().isCreateable() == false && myType.getDescribe().isUpdateable() == false) {
            fl.isSuccess = false;
            fl.message = 'Insufficient access for '+myType +'creation';
            return fl;
        }

        FLSCheckWrapper flsNew = new FLSCheck('upsert').check(objList, myType);
        if(flsNew.isSuccess){
            Database.UpsertResult[] sRList = Database.upsert(objList);
            for(Database.UpsertResult sr : sRList){
                if(sr.isSuccess()){
                    fl.isSuccess = true;
                }else{
                    fl.isSuccess = false;
                    fl.message = 'Something went wrong.';
                    break;
                }
            }
            
        }else{
            fl.isSuccess = false;
            fl.message = flsNew.message;
        }

        return fl;
    }

    /**
     * @description method to check update permissions for list of Sobjects 
     * @return FLSCheckWrapper
     * @param objList
    */
    public static FLSCheckWrapper dmlUpdate(List<SObject> objList){
        FLSCheckWrapper fl = new FLSCheckWrapper();
        
        if (objList == null || objList.isEmpty()){
            fl.isSuccess = false;
            fl.message = 'No data found.';
            return fl;

        }
        SObjectType myType = objList[0].getSObjectType();

        if (myType.getDescribe().isUpdateable() == false) {
            fl.isSuccess = false;
            fl.message = 'Insufficient access for '+myType +'creation';
            return fl;
        }

        FLSCheckWrapper flsNew = new FLSCheck('update').check(objList, myType);
        if(flsNew.isSuccess){
            Database.SaveResult[] sRList = Database.update(objList);
            for(Database.SaveResult sr : sRList){
                if(sr.isSuccess()){
                    fl.isSuccess = true;
                }else{
                    fl.isSuccess = false;
                    fl.message = 'Something went wrong.';
                    break;
                }
            }
            
        }else{
            fl.isSuccess = false;
            fl.message = flsNew.message;
        }
        return fl;
    }

    /**
     * @description method to check delete permissions for list of Sobjects 
     * @return FLSCheckWrapper
     * @param objList
    */
    public static FLSCheckWrapper dmlDelete(List<SObject> objList){
        FLSCheckWrapper fl = new FLSCheckWrapper();
        
        if (objList == null || objList.isEmpty()){
            fl.isSuccess = false;
            fl.message = 'No data found.';
            return fl;

        }
        SObjectType myType = objList[0].getSObjectType();

        if (myType.getDescribe().isDeletable() == false) {
            fl.isSuccess = false;
            fl.message = 'Insufficient access for '+myType +'creation';
            return fl;
        }else{
            Database.DeleteResult[] sRList = Database.delete(objList);
            for(Database.DeleteResult sr : sRList){
                if(sr.isSuccess()){
                    fl.isSuccess = true;
                }else{
                    fl.isSuccess = false;
                    fl.message = 'Something went wrong.';
                    break;
                }
            }
        }
        return fl;
    }

    /**
     * @description Class to check FLS and object permissions for CRUD operations
    */
    public class FLSCheck {
        private String operation;
        /**
         * @description constructor for variable initialization
         * @param operation
        */
        public FLSCheck(String operation) {
            this.operation = operation;
        }
        
        /**
         * @description method to check update permissions for List of Sobjects passed 
         * @return FLSCheckWrapper
         * @param objList
         * @param myType
        */
        public FLSCheckWrapper check(SObject[] objList, SObjectType myType) {
            
            FLSCheckWrapper fl = new FLSCheckWrapper();
            fl.isSuccess = true;
            fl.message = '';
            Set<String> fieldList = new Set<String>();
            
            for (SObject so : objList) {
                Map<String, Schema.SObjectField> fieldMap = myType.getDescribe().fields.getMap();
                for (String fieldName : so.getPopulatedFieldsAsMap().keySet()) {
                    if (fieldName == 'Id'){
                        continue;
                    } 
                    if (fieldName == 'Geolocation__c'){
                        continue;
                    }

                    Schema.SObjectField myField = fieldMap.get(fieldName);

                    if (myField == null){
                        continue;
                    }
                    
                    if (this.operation == 'update') {
                        if (myField.getDescribe().isUpdateable() == false) {
                            fieldList.add(myField+'');
                            continue;
                        }
                    } else if(this.operation == 'insert'){
                        if (myField.getDescribe().isCreateable() == false) {
                            fieldList.add(myField+'');
                            continue;
                        }                        
                    
                    } else if(this.operation == 'upsert'){
                        if (myField.getDescribe().isCreateable() == false && myField.getDescribe().isUpdateable() == false) {
                            fieldList.add(myField+'');
                            continue;
                        }                        
                    }
                }
                if(fieldList.size() > 0){
                    string fieldStr = '';
                    for(String str : fieldList){
                        fieldStr += str+', ';
                    }
                    fieldStr = fieldStr.removeEnd(', ');
                    fl.isSuccess = false;
                    fl.message = 'Insufficient access for '+fieldStr; 
                }
            }
            return fl;
        }

       

    }

     /**
     * @description Class to manage Xero contact details
    */
    public class FLSCheckWrapper{
        public Boolean isSuccess ;
        public String message ;
    }
    
}