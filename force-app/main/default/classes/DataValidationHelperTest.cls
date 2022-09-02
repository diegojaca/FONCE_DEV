/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 05-26-2022
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
**/
@IsTest
public with sharing class DataValidationHelperTest {

    private static final String  TEST_LASTNAME = 'test lastname';
    private static final String TEST_DOCUMENT_NUMBER_NIF = '11442220L';
    private static final String  TEST_ACCOUNT_NAME = 'test accName';
    private static final String TEST_DOCUMENT_NUMBER_CIF = 'P9375828B';
    private static final String TEST_DOCUMENT_NUMBER_NIE = 'X2893218W';
    
    @TestSetup
    static void makeData(){
        
        Contact contact = PrepareTestData.createContact(TEST_LASTNAME);
        contact.N_mero_de_Documento__c = TEST_DOCUMENT_NUMBER_NIF;
        insert contact;

        Account account = PrepareTestData.createAccount(TEST_ACCOUNT_NAME);
        account.N_mero_de_Documento__c  = TEST_DOCUMENT_NUMBER_CIF;
        insert account;

    }

    @IsTest
    static void validateContactOk(){

        Contact contact = [SELECT N_mero_de_Documento__c FROM Contact LIMIT 1];

        Test.startTest();
            Contact result = (Contact)DataValidationHelper.validateData(contact);
        Test.stopTest();

        System.assertEquals(contact.Id, result.Id, 'The contact ids aren´t same');
    }

    @IsTest
    static void validateAccountOk(){

        Account account = [SELECT N_mero_de_Documento__c FROM Account WHERE N_mero_de_Documento__c <> null LIMIT 1];

        Test.startTest();
            Account result = (Account)DataValidationHelper.validateData(account);
        Test.stopTest();

        System.assertEquals(account.Id, result.Id, 'The account ids aren´t same');
    }

    @IsTest
    static void verifyNIEOk(){

        Test.startTest();
            Boolean result = DataValidationHelper.verifyNIE(TEST_DOCUMENT_NUMBER_NIE);
        Test.stopTest();

        System.assertEquals(true, result, 'The NIE isn´t correct');
    }

}