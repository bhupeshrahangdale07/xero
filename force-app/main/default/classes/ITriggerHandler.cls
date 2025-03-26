/*
@Author : Yash Patel | Kandisa Technologies
@Description : Trigger Handler Interface to call in Every Trigger
@CreatedDate : 15 Feb 2022
*/
public interface ITriggerHandler{
     
    void beforeInsert(List<sObject> newList);
     
    void afterInsert(List<sObject> newList, Map<Id, sObject> newMap);
     
    void beforeUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap);
     
    void afterUpdate(List<sObject> newList, Map<Id, sObject> newMap,  List<sObject> oldList, Map<Id, sObject> oldMap);
              
    void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap);
     
    void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap);
     
    void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap);
     
    Boolean isDisabled();
}