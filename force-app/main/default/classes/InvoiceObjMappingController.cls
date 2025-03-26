public with sharing class InvoiceObjMappingController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, ObjectProperties> getObjectList() {

        Map<String, ObjectProperties> objectMap = new Map<String, ObjectProperties>();

        Map<String, Schema.SObjectType> gdResult = Schema.getGlobalDescribe();
        for (Schema.SObjectType s : gdResult.values()) {

            Schema.DescribeSObjectResult od = s.getDescribe();

            String name = od.getName();

            if(od.isAccessible() && od.isCreateable() &&
                !name.containsignorecase('history') && !name.containsignorecase('tag') &&
                !name.containsignorecase('share') && !name.containsignorecase('feed') && 
                !name.containsignorecase('group') && !name.containsignorecase('public')
                ){
                ObjectProperties o = new ObjectProperties();
                o.name = od.getName();
                o.label = od.getLabel();
                o.reference = od.getLabel() + ' (' + od.getName() +')';
                objectMap.put(o.Name, o);
            }
        }

        return objectMap;
    }

    @AuraEnabled
    public static Map<String, List<ObjectProperties>> getObjectFields(String objectApiName){
        System.debug('objectApiName-->'+objectApiName);
        Map<String, ObjectProperties> fieldMap = new Map<String, ObjectProperties>();
        Map <String,Schema.SObjectType> gd = Schema.getGlobalDescribe();

        Map<String, List<ObjectProperties>> fMap = new Map<String, List<ObjectProperties>>();

        Schema.SObjectType sobjType = gd.get(objectApiName);
        Schema.DescribeSObjectResult r = sobjType.getDescribe();
        Map<String, Schema.SObjectField> mapofField = r.fields.getMap();
        for(String fieldName : mapofField.keySet()){
            Schema.SObjectField field = mapofField.get(fieldName);
            Schema.DescribeFieldResult f = field.getDescribe();
            ObjectProperties o = new ObjectProperties();
            o.name = f.getName();
            o.label = f.getLabel();
            o.type = String.valueOf(f.getType());
            o.reference = f.getLabel() + ' (' + f.getName() +')';
            if(o.type == 'REFERENCE'){
                List<Schema.sObjectType> objList = f.getReferenceTo();
                String str = '';
                for(Schema.sObjectType so : objList){
                    str += so.getDescribe().name + ',';
                }
                str = str.removeEnd(',');
                System.debug('str-->'+str);
                o.referenceObj = str;
            }
            fieldMap.put(o.Name, o);

            if(!fMap.containsKey(o.type)){
                fMap.put(o.type, new List<ObjectProperties>());
            }
            fMap.get(o.type).add(o);
        }

        return fMap;
    }

    @AuraEnabled
    public static Map<String, ObjectProperties> getChildObjects(String objectApiName){
        Map<String, ObjectProperties> objectMap = new Map<String, ObjectProperties>();

        Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
        
        for (Schema.ChildRelationship cr : objDescribe.getChildRelationships()) {
            Schema.DescribeSObjectResult od = cr.getChildSObject().getDescribe();

            String name = od.getName();
            
            if(od.isAccessible() && od.isCreateable() &&
                !name.containsignorecase('history') && !name.containsignorecase('tag') &&
                !name.containsignorecase('share') && !name.containsignorecase('feed') && 
                !name.containsignorecase('group') && !name.containsignorecase('public')
            ){
                ObjectProperties o = new ObjectProperties();
                o.name = od.getName();
                o.label = od.getLabel();
                o.reference = od.getLabel() + ' (' + od.getName() +')';
                o.relationShipName = cr.getRelationshipName();
                objectMap.put(o.Name, o);
            }
        }

        return objectMap;
    }

    @AuraEnabled
    public static SelectedObjects getSelectedObjects(){
        SelectedObjects so = new SelectedObjects();
        try {
            KTXero__Invoice_Configuration_Options__c invConfig = KTXero__Invoice_Configuration_Options__c.getOrgDefaults();

            so.invoiceObj = invConfig.KTXero__Invoice_Mapping_Obj__c;
            so.invoiceLineItemObj = invConfig.KTXero__Invoice_LineItem_Mapping_Obj__c;
            so.invoicePaymentObj = invConfig.KTXero__Invoice_Payment_Mapping_Obj__c;
            so.xeroContactObj = invConfig.KTXero__Xero_Contact_Mapping_Object__c;
            so.billObj = invConfig.KTXero__Bill_Mapping_Obj__c;
            so.billLiObj = invConfig.KTXero__Bill_LineItem_Mapping_Obj__c;
            so.billPaymentObj = invConfig.KTXero__Bill_Payment_Mapping_Obj__c;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return so;
    }

    @AuraEnabled
    public static List<InvoiceObjMappingWrapper> getInvoiceMappingCS(){
        List<InvoiceObjMappingWrapper> listOfObjMapping = new List<InvoiceObjMappingWrapper>();
        try {
            // Find all the countries in the custom setting
            Map<String, KTXero__Invoice_Object_Field_Mapping__c> invMap = KTXero__Invoice_Object_Field_Mapping__c.getAll();

            for(String str : invMap.keySet()){
                KTXero__Invoice_Object_Field_Mapping__c invCustomSetting = invMap.get(str);
                InvoiceObjMappingWrapper invObjMapping = new InvoiceObjMappingWrapper();
                invObjMapping.id = invCustomSetting.Id;
                invObjMapping.name = invCustomSetting.Name;
                invObjMapping.dataType = invCustomSetting.KTXero__Data_Type__c;
                invObjMapping.fieldApiName = invCustomSetting.KTXero__Field_API_Name__c;
                invObjMapping.fieldValue = invCustomSetting.KTXero__Field_Value__c;
                invObjMapping.helpText = invCustomSetting.KTXero__Help_Text__c;
                invObjMapping.xeroField = invCustomSetting.KTXero__Xero_Field_Name__c;
                invObjMapping.readOnly = invCustomSetting.KTXero__Read_only__c;
                invObjMapping.required = invCustomSetting.KTXero__Required__c;
                invObjMapping.referenceObjName = invCustomSetting.KTXero__Reference_Object_Name__c;
                invObjMapping.sequence = invCustomSetting.KTXero__Sequence_Number__c;
                listOfObjMapping.add(invObjMapping);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return listOfObjMapping;
    }

    @AuraEnabled
    public static Boolean saveInvoiceMappingCS(String invString){
        Boolean flag = false;
        List<InvoiceObjMappingWrapper> invCSList = new List<InvoiceObjMappingWrapper>();
        List<KTXero__Invoice_Object_Field_Mapping__c> invMapList = new List<KTXero__Invoice_Object_Field_Mapping__c>();
        try {
            invCSList = (List<InvoiceObjMappingWrapper>)JSON.deserialize(invString,List<InvoiceObjMappingWrapper>.class);

            for(InvoiceObjMappingWrapper iow : invCSList){
                KTXero__Invoice_Object_Field_Mapping__c iofm = new KTXero__Invoice_Object_Field_Mapping__c();
                iofm.Id = iow.id;
                iofm.KTXero__Field_API_Name__c = iow.fieldApiName;
                invMapList.add(iofm);
            }

            FLSChecker.FLSCheckWrapper flsWrap = FLSChecker.dmlUpdate(invMapList);
            if(!flsWrap.isSuccess){
                throw new AuraHandledException(flsWrap.message);
            } else {
                flag = true;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return flag;
    }
    
    @AuraEnabled
    public static List<InvoiceObjMappingWrapper> getInvoiceLIMappingCS(){
        List<InvoiceObjMappingWrapper> listOfObjMapping = new List<InvoiceObjMappingWrapper>();
        try {
            // Find all the countries in the custom setting
            Map<String, KTXero__Invoice_LineItem_Obj_Field_Mapping__c> invMap = KTXero__Invoice_LineItem_Obj_Field_Mapping__c.getAll();

            for(String str : invMap.keySet()){
                KTXero__Invoice_LineItem_Obj_Field_Mapping__c invCustomSetting = invMap.get(str);
                InvoiceObjMappingWrapper invObjMapping = new InvoiceObjMappingWrapper();
                invObjMapping.id = invCustomSetting.Id;
                invObjMapping.name = invCustomSetting.Name;
                invObjMapping.dataType = invCustomSetting.KTXero__Data_Type__c;
                invObjMapping.fieldApiName = invCustomSetting.KTXero__Field_API_Name__c;
                invObjMapping.fieldValue = invCustomSetting.KTXero__Field_Value__c;
                invObjMapping.helpText = invCustomSetting.KTXero__Help_Text__c;
                invObjMapping.xeroField = invCustomSetting.KTXero__Xero_Field_Name__c;
                invObjMapping.readOnly = invCustomSetting.KTXero__Read_only__c;
                invObjMapping.required = invCustomSetting.KTXero__Required__c;
                invObjMapping.referenceObjName = invCustomSetting.KTXero__Reference_Object_Name__c;
                invObjMapping.sequence = invCustomSetting.KTXero__Sequence_Number__c;
                listOfObjMapping.add(invObjMapping);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return listOfObjMapping;
    }

    @AuraEnabled
    public static Boolean saveInvoiceLIMappingCS(String invString){
        Boolean flag = false;
        List<InvoiceObjMappingWrapper> invCSList = new List<InvoiceObjMappingWrapper>();
        List<KTXero__Invoice_LineItem_Obj_Field_Mapping__c> invMapList = new List<KTXero__Invoice_LineItem_Obj_Field_Mapping__c>();
        try {
            invCSList = (List<InvoiceObjMappingWrapper>)JSON.deserialize(invString,List<InvoiceObjMappingWrapper>.class);

            for(InvoiceObjMappingWrapper iow : invCSList){
                KTXero__Invoice_LineItem_Obj_Field_Mapping__c iofm = new KTXero__Invoice_LineItem_Obj_Field_Mapping__c();
                iofm.Id = iow.id;
                iofm.KTXero__Field_API_Name__c = iow.fieldApiName;
                invMapList.add(iofm);
            }

            FLSChecker.FLSCheckWrapper flsWrap = FLSChecker.dmlUpdate(invMapList);
            if(!flsWrap.isSuccess){
                throw new AuraHandledException(flsWrap.message);
            } else {
                flag = true;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return flag;
    }
    
    @AuraEnabled
    public static List<InvoiceObjMappingWrapper> getInvoicePayMappingCS(){
        List<InvoiceObjMappingWrapper> listOfObjMapping = new List<InvoiceObjMappingWrapper>();
        try {
            // Find all the countries in the custom setting
            Map<String, KTXero__Invoice_Payment_Object_Field_Mapping__c> invMap = KTXero__Invoice_Payment_Object_Field_Mapping__c.getAll();

            for(String str : invMap.keySet()){
                KTXero__Invoice_Payment_Object_Field_Mapping__c invCustomSetting = invMap.get(str);
                InvoiceObjMappingWrapper invObjMapping = new InvoiceObjMappingWrapper();
                invObjMapping.id = invCustomSetting.Id;
                invObjMapping.name = invCustomSetting.Name;
                invObjMapping.dataType = invCustomSetting.KTXero__Data_Type__c;
                invObjMapping.fieldApiName = invCustomSetting.KTXero__Field_API_Name__c;
                invObjMapping.fieldValue = invCustomSetting.KTXero__Field_Value__c;
                invObjMapping.helpText = invCustomSetting.KTXero__Help_Text__c;
                invObjMapping.xeroField = invCustomSetting.KTXero__Xero_Field_Name__c;
                invObjMapping.readOnly = invCustomSetting.KTXero__Read_only__c;
                invObjMapping.required = invCustomSetting.KTXero__Required__c;
                // invObjMapping.referenceObjName = invCustomSetting.KTXero__Reference_Object_Name__c;
                listOfObjMapping.add(invObjMapping);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return listOfObjMapping;
    }

    @AuraEnabled
    public static Boolean saveInvoicePayMappingCS(String invString){
        Boolean flag = false;
        List<InvoiceObjMappingWrapper> invCSList = new List<InvoiceObjMappingWrapper>();
        List<KTXero__Invoice_Payment_Object_Field_Mapping__c> invMapList = new List<KTXero__Invoice_Payment_Object_Field_Mapping__c>();
        try {
            invCSList = (List<InvoiceObjMappingWrapper>)JSON.deserialize(invString,List<InvoiceObjMappingWrapper>.class);

            for(InvoiceObjMappingWrapper iow : invCSList){
                KTXero__Invoice_Payment_Object_Field_Mapping__c iofm = new KTXero__Invoice_Payment_Object_Field_Mapping__c();
                iofm.Id = iow.id;
                iofm.KTXero__Field_API_Name__c = iow.fieldApiName;
                invMapList.add(iofm);
            }

            FLSChecker.FLSCheckWrapper flsWrap = FLSChecker.dmlUpdate(invMapList);
            if(!flsWrap.isSuccess){
                throw new AuraHandledException(flsWrap.message);
            } else {
                flag = true;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return flag;
    }
    
    @AuraEnabled
    public static List<InvoiceObjMappingWrapper> getXeroConMappingCS(){
        List<InvoiceObjMappingWrapper> listOfObjMapping = new List<InvoiceObjMappingWrapper>();
        try {
            // Find all the countries in the custom setting
            Map<String, KTXero__Xero_Contact_Object_Field_Mapping__c> invMap = KTXero__Xero_Contact_Object_Field_Mapping__c.getAll();

            for(String str : invMap.keySet()){
                KTXero__Xero_Contact_Object_Field_Mapping__c invCustomSetting = invMap.get(str);
                InvoiceObjMappingWrapper invObjMapping = new InvoiceObjMappingWrapper();
                invObjMapping.id = invCustomSetting.Id;
                invObjMapping.name = invCustomSetting.Name;
                invObjMapping.dataType = invCustomSetting.KTXero__Data_Type__c;
                invObjMapping.fieldApiName = invCustomSetting.KTXero__Field_API_Name__c;
                invObjMapping.fieldValue = invCustomSetting.KTXero__Field_Value__c;
                invObjMapping.helpText = invCustomSetting.KTXero__Help_Text__c;
                invObjMapping.xeroField = invCustomSetting.KTXero__Xero_Field_Name__c;
                invObjMapping.readOnly = invCustomSetting.KTXero__Read_only__c;
                invObjMapping.required = invCustomSetting.KTXero__Required__c;
                invObjMapping.referenceObjName = invCustomSetting.KTXero__Reference_Object_Name__c;
                invObjMapping.sequence = invCustomSetting.KTXero__Sequence_Number__c;
                listOfObjMapping.add(invObjMapping);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return listOfObjMapping;
    }

    @AuraEnabled
    public static Boolean saveXeroConMappingCS(String invString, String mappedObj){
        Boolean flag = false;
        List<InvoiceObjMappingWrapper> invCSList = new List<InvoiceObjMappingWrapper>();
        List<KTXero__Xero_Contact_Object_Field_Mapping__c> invMapList = new List<KTXero__Xero_Contact_Object_Field_Mapping__c>();
        try {
            invCSList = (List<InvoiceObjMappingWrapper>)JSON.deserialize(invString,List<InvoiceObjMappingWrapper>.class);

            for(InvoiceObjMappingWrapper iow : invCSList){
                KTXero__Xero_Contact_Object_Field_Mapping__c iofm = new KTXero__Xero_Contact_Object_Field_Mapping__c();
                iofm.Id = iow.id;
                iofm.KTXero__Field_API_Name__c = iow.fieldApiName;
                invMapList.add(iofm);
            }

            FLSChecker.FLSCheckWrapper flsWrap = FLSChecker.dmlUpdate(invMapList);
            if(!flsWrap.isSuccess){
                throw new AuraHandledException(flsWrap.message);
            } else {
                flag = true;
            }

            // check and update the Mapped Object Api Name in Custom Settings Records
            KTXero__Invoice_Configuration_Options__c invConfig = [SELECT Id, KTXero__Xero_Contact_Mapping_Object__c FROM KTXero__Invoice_Configuration_Options__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED];
            
            if(invConfig.KTXero__Xero_Contact_Mapping_Object__c != mappedObj){
                
                // Update the Invoice Configuration custom setting
                invConfig.KTXero__Xero_Contact_Mapping_Object__c = mappedObj;
                if(invConfig.getSObjectType().getDescribe().isUpdateable() == true &&
                    Schema.sObjectType.KTXero__Invoice_Configuration_Options__c.fields.KTXero__Xero_Contact_Mapping_Object__c.isUpdateable() == true){
                    database.SaveResult sr = database.update(invConfig);
                    if(sr.isSuccess()){
                        flag = true;
                    }else{
                        flag = false;
                    }
                }

                // Update the Refernce Objecct Name field of Invoice Object field Mapping custom setting
                List<KTXero__Invoice_Object_Field_Mapping__c> objMapping = [SELECT Id, KTXero__Reference_Object_Name__c FROM KTXero__Invoice_Object_Field_Mapping__c WHERE Name = 'Xero Contact' LIMIT 1];
                objMapping[0].KTXero__Reference_Object_Name__c = mappedObj;

                FLSChecker.FLSCheckWrapper flsWrap1 = FLSChecker.dmlUpdate(objMapping);
                if(!flsWrap1.isSuccess){
                    throw new AuraHandledException(flsWrap1.message);
                } else {
                    flag = true;
                }
                
                // Update the Refernce Objecct Name field of Bill Object field Mapping custom setting
                List<KTXero__Bill_Object_Field_Mapping__c> billobjMapping = [SELECT Id, KTXero__Reference_Object_Name__c FROM KTXero__Bill_Object_Field_Mapping__c WHERE Name = 'Xero Contact' LIMIT 1];
                billobjMapping[0].KTXero__Reference_Object_Name__c = mappedObj;

                FLSChecker.FLSCheckWrapper flsWrap2 = FLSChecker.dmlUpdate(billobjMapping);
                if(!flsWrap2.isSuccess){
                    throw new AuraHandledException(flsWrap2.message);
                } else {
                    flag = true;
                }

            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return flag;
    }
    
    @AuraEnabled
    public static List<InvoiceObjMappingWrapper> getBillMappingCS(){
        List<InvoiceObjMappingWrapper> listOfObjMapping = new List<InvoiceObjMappingWrapper>();
        try {
            Map<String, KTXero__Bill_Object_Field_Mapping__c> billMap = KTXero__Bill_Object_Field_Mapping__c.getAll();

            for(String str : billMap.keySet()){
                KTXero__Bill_Object_Field_Mapping__c invCustomSetting = billMap.get(str);
                InvoiceObjMappingWrapper invObjMapping = new InvoiceObjMappingWrapper();
                invObjMapping.id = invCustomSetting.Id;
                invObjMapping.name = invCustomSetting.Name;
                invObjMapping.dataType = invCustomSetting.KTXero__Data_Type__c;
                invObjMapping.fieldApiName = invCustomSetting.KTXero__Field_API_Name__c;
                invObjMapping.fieldValue = invCustomSetting.KTXero__Field_Value__c;
                invObjMapping.helpText = invCustomSetting.KTXero__Help_Text__c;
                invObjMapping.xeroField = invCustomSetting.KTXero__Xero_Field_Name__c;
                invObjMapping.readOnly = invCustomSetting.KTXero__Read_only__c;
                invObjMapping.required = invCustomSetting.KTXero__Required__c;
                invObjMapping.referenceObjName = invCustomSetting.KTXero__Reference_Object_Name__c;
                invObjMapping.sequence = invCustomSetting.KTXero__Sequence_Number__c;
                listOfObjMapping.add(invObjMapping);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return listOfObjMapping;
    }

    @AuraEnabled
    public static Boolean saveBillMappingCS(String invString){
        Boolean flag = false;
        List<InvoiceObjMappingWrapper> invCSList = new List<InvoiceObjMappingWrapper>();
        List<KTXero__Bill_Object_Field_Mapping__c> invMapList = new List<KTXero__Bill_Object_Field_Mapping__c>();
        try {
            invCSList = (List<InvoiceObjMappingWrapper>)JSON.deserialize(invString,List<InvoiceObjMappingWrapper>.class);

            for(InvoiceObjMappingWrapper iow : invCSList){
                KTXero__Bill_Object_Field_Mapping__c iofm = new KTXero__Bill_Object_Field_Mapping__c();
                iofm.Id = iow.id;
                iofm.KTXero__Field_API_Name__c = iow.fieldApiName;
                invMapList.add(iofm);
            }

            FLSChecker.FLSCheckWrapper flsWrap = FLSChecker.dmlUpdate(invMapList);
            if(!flsWrap.isSuccess){
                throw new AuraHandledException(flsWrap.message);
            } else {
                flag = true;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return flag;
    }
    
    @AuraEnabled
    public static List<InvoiceObjMappingWrapper> getBillLiMappingCS(){
        List<InvoiceObjMappingWrapper> listOfObjMapping = new List<InvoiceObjMappingWrapper>();
        try {
            Map<String, KTXero__Bill_LineItem_Object_Field_Mapping__c> billMap = KTXero__Bill_LineItem_Object_Field_Mapping__c.getAll();

            for(String str : billMap.keySet()){
                KTXero__Bill_LineItem_Object_Field_Mapping__c invCustomSetting = billMap.get(str);
                InvoiceObjMappingWrapper invObjMapping = new InvoiceObjMappingWrapper();
                invObjMapping.id = invCustomSetting.Id;
                invObjMapping.name = invCustomSetting.Name;
                invObjMapping.dataType = invCustomSetting.KTXero__Data_Type__c;
                invObjMapping.fieldApiName = invCustomSetting.KTXero__Field_API_Name__c;
                invObjMapping.fieldValue = invCustomSetting.KTXero__Field_Value__c;
                invObjMapping.helpText = invCustomSetting.KTXero__Help_Text__c;
                invObjMapping.xeroField = invCustomSetting.KTXero__Xero_Field_Name__c;
                invObjMapping.readOnly = invCustomSetting.KTXero__Read_only__c;
                invObjMapping.required = invCustomSetting.KTXero__Required__c;
                invObjMapping.referenceObjName = invCustomSetting.KTXero__Reference_Object_Name__c;
                invObjMapping.sequence = invCustomSetting.KTXero__Sequence_Number__c;
                listOfObjMapping.add(invObjMapping);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return listOfObjMapping;
    }

    @AuraEnabled
    public static Boolean saveBillLiMappingCS(String invString){
        Boolean flag = false;
        List<InvoiceObjMappingWrapper> invCSList = new List<InvoiceObjMappingWrapper>();
        List<KTXero__Bill_LineItem_Object_Field_Mapping__c> invMapList = new List<KTXero__Bill_LineItem_Object_Field_Mapping__c>();
        try {
            invCSList = (List<InvoiceObjMappingWrapper>)JSON.deserialize(invString,List<InvoiceObjMappingWrapper>.class);

            for(InvoiceObjMappingWrapper iow : invCSList){
                KTXero__Bill_LineItem_Object_Field_Mapping__c iofm = new KTXero__Bill_LineItem_Object_Field_Mapping__c();
                iofm.Id = iow.id;
                iofm.KTXero__Field_API_Name__c = iow.fieldApiName;
                invMapList.add(iofm);
            }

            FLSChecker.FLSCheckWrapper flsWrap = FLSChecker.dmlUpdate(invMapList);
            if(!flsWrap.isSuccess){
                throw new AuraHandledException(flsWrap.message);
            } else {
                flag = true;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return flag;
    }

    @AuraEnabled
    public static List<InvoiceObjMappingWrapper> getBillPayMappingCS(){
        List<InvoiceObjMappingWrapper> listOfObjMapping = new List<InvoiceObjMappingWrapper>();
        try {
            // Find all the countries in the custom setting
            Map<String, KTXero__Bill_Payment_Object_Field_Mapping__c> invMap = KTXero__Bill_Payment_Object_Field_Mapping__c.getAll();

            for(String str : invMap.keySet()){
                KTXero__Bill_Payment_Object_Field_Mapping__c invCustomSetting = invMap.get(str);
                InvoiceObjMappingWrapper invObjMapping = new InvoiceObjMappingWrapper();
                invObjMapping.id = invCustomSetting.Id;
                invObjMapping.name = invCustomSetting.Name;
                invObjMapping.dataType = invCustomSetting.KTXero__Data_Type__c;
                invObjMapping.fieldApiName = invCustomSetting.KTXero__Field_API_Name__c;
                invObjMapping.fieldValue = invCustomSetting.KTXero__Field_Value__c;
                invObjMapping.helpText = invCustomSetting.KTXero__Help_Text__c;
                invObjMapping.xeroField = invCustomSetting.KTXero__Xero_Field_Name__c;
                invObjMapping.readOnly = invCustomSetting.KTXero__Read_only__c;
                invObjMapping.required = invCustomSetting.KTXero__Required__c;
                invObjMapping.referenceObjName = invCustomSetting.KTXero__Reference_Object_Name__c;
                listOfObjMapping.add(invObjMapping);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return listOfObjMapping;
    }

    @AuraEnabled
    public static Boolean saveBillPayMappingCS(String invString){
        Boolean flag = false;
        List<InvoiceObjMappingWrapper> invCSList = new List<InvoiceObjMappingWrapper>();
        List<KTXero__Bill_Payment_Object_Field_Mapping__c> invMapList = new List<KTXero__Bill_Payment_Object_Field_Mapping__c>();
        try {
            invCSList = (List<InvoiceObjMappingWrapper>)JSON.deserialize(invString,List<InvoiceObjMappingWrapper>.class);

            for(InvoiceObjMappingWrapper iow : invCSList){
                KTXero__Bill_Payment_Object_Field_Mapping__c iofm = new KTXero__Bill_Payment_Object_Field_Mapping__c();
                iofm.Id = iow.id;
                iofm.KTXero__Field_API_Name__c = iow.fieldApiName;
                invMapList.add(iofm);
            }

            FLSChecker.FLSCheckWrapper flsWrap = FLSChecker.dmlUpdate(invMapList);
            if(!flsWrap.isSuccess){
                throw new AuraHandledException(flsWrap.message);
            } else {
                flag = true;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return flag;
    }

    public class ObjectProperties {
        @AuraEnabled public String name {get; set;} // Object API Name
        @AuraEnabled public String label {get; set;} // Object Label
        @AuraEnabled public String reference {get; set;} // reference will be the value displayed to the user. There can be objects with the same label.
        @AuraEnabled public String type {get; set;} // Object type name
        @AuraEnabled public String referenceObj {get; set;} // Object type name
        @AuraEnabled public String relationShipName {get; set;} // Store relationship name
    }

    public class SelectedObjects {
        @AuraEnabled public string invoiceObj {get;set;}
        @AuraEnabled public string invoicelineItemObj {get;set;}
        @AuraEnabled public string invoicePaymentObj {get;set;}
        @AuraEnabled public string xeroContactObj {get;set;}
        @AuraEnabled public string billObj {get;set;}
        @AuraEnabled public string billLiObj {get;set;}
        @AuraEnabled public string billPaymentObj {get;set;}
    }

    public class InvoiceObjMappingWrapper{
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public String dataType {get;set;}
        @AuraEnabled public String fieldApiName {get;set;}
        @AuraEnabled public String fieldValue {get;set;}
        @AuraEnabled public String helpText {get;set;}
        @AuraEnabled public String xeroField {get;set;}
        @AuraEnabled public Boolean readOnly {get;set;}
        @AuraEnabled public Boolean required {get;set;}
        @AuraEnabled public String referenceObjName {get;set;}
        @AuraEnabled public Decimal sequence {get;set;}
    }
}