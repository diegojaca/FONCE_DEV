/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 07-01-2022
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
**/
@IsTest
public with sharing class S4GUtilsTest {

    private static final String  TEST_LASTNAME_1 = 'test lastname 1';
    private static final String  TEST_LASTNAME_2 = 'test lastname 2';
    private static final String  DOC_NUMBER_EXT_ID_1 = '123456789';
    private static final String  DOC_NUMBER_EXT_ID_2 = '123456780';
    
    @IsTest
    static void isChangedOk(){

        Contact oldContact = PrepareTestData.createContact(TEST_LASTNAME_1);
        oldContact.N_mero_de_Documento__c = DOC_NUMBER_EXT_ID_1;

        Contact newContact = PrepareTestData.createContact(TEST_LASTNAME_2);
        newContact.N_mero_de_Documento__c = DOC_NUMBER_EXT_ID_2;

        Test.startTest();
            Boolean result1 = S4GUtils.isChanged(newContact, oldContact, new List<String>{'N_mero_de_Documento__c'});
            Boolean result2 = S4GUtils.isChanged(newContact, newContact, new List<String>{'N_mero_de_Documento__c'});
            Boolean result3 = S4GUtils.isChanged(newContact, newContact, 'N_mero_de_Documento__c');
        Test.stopTest();

        System.assertEquals(true, result1, 'Does not has changed the field');
        System.assertEquals(false, result2, 'The field value  changed');
        System.assertEquals(false, result3, 'The field value  changed');
    }

    @IsTest
    static void getAllFieldsInSObjectOk(){

        Test.startTest();
            List<String> standardFields = S4GUtils.getAllFieldsInSObject('Account', false, true);
            List<String> customFields = S4GUtils.getAllFieldsInSObject('Account', true, false);
        Test.stopTest();

        System.assertEquals(true, standardFields.contains('Name'), 'Must be contains stardard field name');
        System.assertEquals(false, customFields.contains('Name'), 'Must not contains stardard field name');
    }

    @IsTest
    static void getDependentPicklistValuesOk(){

        Test.startTest();
            Map<String, List<String>> typeRequirementsByFundingRequestStatus = S4GUtils.getDependentPicklistValues(outfunds__Funding_Request__c.Type_Requirement__c);
        Test.stopTest();

        System.assertNotEquals(null, typeRequirementsByFundingRequestStatus, 'Must be return not null');
    }

    @IsTest
    static void joinStringsForInStatementOk(){

        List<String> testList = new List<String>{'01','02','03','04','05'};

        Test.startTest();
        String result = S4GUtils.joinStringsForInStatement(testList);
        Test.stopTest();

        System.assertEquals('\'01\',\'02\',\'03\',\'04\',\'05\'', result, 'Must be same string');
    }

    @IsTest
    static void getSObjectLabelByIdTest(){

        Contact contact = PrepareTestData.createContact(TEST_LASTNAME_1);
        insert contact;

        Test.startTest();
            String sObjectLabel = S4GUtils.getSObjectLabelById(contact.Id);
        Test.stopTest();

        System.assertEquals(Schema.Contact.getSObjectType().getDescribe().getLabel(), sObjectLabel, '´sObject label isn´t the same');
    }
}