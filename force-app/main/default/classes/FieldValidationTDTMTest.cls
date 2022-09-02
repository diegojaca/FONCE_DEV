/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 05-30-2022
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
**/
@Istest
public with sharing class FieldValidationTDTMTest {

    private static final String  TEST_LASTNAME = 'test lastname';
    private static final String  TEST_DOCUMENT_NUMBER_NIF = '11442220L';
    private static final String  TEST_DOCUMENT_NUMBER_NIF_2 = '19416114C';

    @Istest
    static void beforeInsertOK(){

        FieldValidationTDTM worker = new FieldValidationTDTM();

        Contact contact = PrepareTestData.createContact(TEST_LASTNAME);
        contact.N_mero_de_Documento__c = TEST_DOCUMENT_NUMBER_NIF;

        Test.startTest();
            worker.beforeInsert(contact);
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM Contact], 'Must be return 0 records');
    }

    @Istest
    static void beforeUpdateOK(){

        FieldValidationTDTM worker = new FieldValidationTDTM();

        Contact contact = PrepareTestData.createContact(TEST_LASTNAME);
        contact.N_mero_de_Documento__c = TEST_DOCUMENT_NUMBER_NIF;
        insert contact;

        Contact clonedContact = contact.clone();
        clonedContact.N_mero_de_Documento__c = TEST_DOCUMENT_NUMBER_NIF_2;

        Test.startTest();
            worker.beforeUpdate(contact, clonedContact);
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM Contact], 'Must be return one records');
    }
}