/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 04-07-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class S4GTestFactory {

    private static Map<String, Map<String, Object>> fieldsToFillTestDataFactoryBySObject = new Map<String, Map<String, Object>>();

    // ----------------------------------------------------------------------------------------------------------
    // -------------
    // TestDataFactory
    // -------------
    // ----------------------------------------------------------------------------------------------------------
    public static void setDefaultValues(String objectApiName, String fieldApiName, Object fieldValue) {
        if (S4GTestFactory.fieldsToFillTestDataFactoryBySObject.containsKey(objectApiName)) {
            S4GTestFactory.fieldsToFillTestDataFactoryBySObject.get(objectApiName).put(fieldApiName, fieldValue);
        } else {
            S4GTestFactory.fieldsToFillTestDataFactoryBySObject.put(objectApiName, new Map<String, Object>{
                    fieldApiName => fieldValue
            });
        }
    }

    public static void includeFields(String objectApiName, String fieldApiName) {
        if (S4GTestFactory.fieldsToFillTestDataFactoryBySObject.containsKey(objectApiName)) {
            if (!S4GTestFactory.fieldsToFillTestDataFactoryBySObject.get(objectApiName).containsKey(fieldApiName)) {
                S4GTestFactory.fieldsToFillTestDataFactoryBySObject.get(objectApiName).put(fieldApiName, TestDataFactory.DEFAULT_VALUE);
            }
        } else {
            S4GTestFactory.fieldsToFillTestDataFactoryBySObject.put(objectApiName, new Map<String, Object>{
                    fieldApiName => TestDataFactory.DEFAULT_VALUE
            });
        }
    }

    public static void includeMultipleFields(String objectApiName, List<String> fieldApiNames) {
        for (String fieldApiName : fieldApiNames) {
            S4GTestFactory.includeFields(objectApiName, fieldApiName);
        }
    }

    public static void removeFieldFromInclude(String objectApiName, String fieldApiName) {
        if (S4GTestFactory.fieldsToFillTestDataFactoryBySObject.containsKey(objectApiName)
                && S4GTestFactory.fieldsToFillTestDataFactoryBySObject.get(objectApiName).containsKey(fieldApiName)) {
            S4GTestFactory.fieldsToFillTestDataFactoryBySObject.get(objectApiName).remove(fieldApiName);
        }
    }

    public static SObject createObject(String objName) {
        return TestDataFactory.createSObject(objName, S4GTestFactory.fieldsToFillTestDataFactoryBySObject.get(objName), false);
    }

    public static List<SObject> createObjects(String objName, Integer nObject) {
        return TestDataFactory.createSObjectList(objName, S4GTestFactory.fieldsToFillTestDataFactoryBySObject.get(objName), nObject, false);
    }
}