/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 06-09-2022
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
**/
@IsTest
public with sharing class MergeContactsHelperTest {

    private static final String CONTACT_LAST_NAME = 'Test lastname' ;
    private static final String CONTACT_LAST_NAME_2 = 'Test lastname_2' ;
    private static final String CONTACT_LAST_NAME_3 = 'Test lastname_3' ;
    private static final String CONTACT_DOCUMENT_NUMBER = 'F21065800' ;
    private static final String CONTACT_DOCUMENT_NUMBER_2 = 'S1116406H' ;
    private static final String CONTACT_DOCUMENT_NUMBER_3 = 'C00636522' ;
    private static final String CONTACT_EMAIL = 'contact.email@test.com' ;
    
    @TestSetup
    static void makeData(){
        
        Contact contact = PrepareTestData.createContact(CONTACT_LAST_NAME);
        contact.N_mero_de_Documento__c = CONTACT_DOCUMENT_NUMBER;
        contact.Email = CONTACT_EMAIL;

        WorkersManager.avoidAllWorkersExecution(true);
        insert contact;
        WorkersManager.avoidAllWorkersExecution(false);
    }

    @IsTest
    static void checkDuplicateContactOk(){

        List<Contact> oldContacts = [SELECT Email FROM Contact];
        System.assertEquals(1, oldContacts.size(), 'Must be return one record');

        //Create contact with same document number
        Contact contact = PrepareTestData.createContact(CONTACT_LAST_NAME_2);
        contact.N_mero_de_Documento__c = CONTACT_DOCUMENT_NUMBER;

        WorkersManager.avoidAllWorkersExecution(true);
        insert contact;
        WorkersManager.avoidAllWorkersExecution(false);

        System.assertEquals(2, [SELECT Count() FROM Contact WHERE N_mero_de_Documento__c =: CONTACT_DOCUMENT_NUMBER], 'Must be return two records');
        System.assertEquals(null, [SELECT Email FROM Contact WHERE Id =: contact.Id].Email, 'Email must be null');

        Test.startTest();
            MergeContactsHelper mergeContacts = new MergeContactsHelper(new List<Contact>{contact});
            mergeContacts.execute();
        Test.stopTest();

        System.assertEquals(oldContacts[0].Email, [SELECT Email FROM Contact WHERE Id =: contact.Id].Email, 'Email must be same of old contact');
        System.assertEquals(1, [SELECT Count() FROM Contact WHERE N_mero_de_Documento__c =: CONTACT_DOCUMENT_NUMBER], 'Merge proccess don´t completed');
    }

    @IsTest
    static void checkMassDuplicateContactOk(){

        List<Contact> oldContacts = [SELECT N_mero_de_Documento__c FROM Contact];
        System.assertEquals(1, oldContacts.size(), 'Must be return one record');

        //Create 20 contacts with same document number
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i < 20; i++){
            Contact c = PrepareTestData.createContact(CONTACT_LAST_NAME_2 + '_' + 1);
            c.N_mero_de_Documento__c = CONTACT_DOCUMENT_NUMBER;
            contacts.add(c);
        }

        WorkersManager.avoidAllWorkersExecution(true);
        insert contacts;
        WorkersManager.avoidAllWorkersExecution(false);

        System.assertEquals(21, [SELECT Count() FROM Contact WHERE N_mero_de_Documento__c =: CONTACT_DOCUMENT_NUMBER], 'Must be return 21 records');

        Test.startTest();
            MergeContactsHelper mergeContacts = new MergeContactsHelper(new List<Contact>{oldContacts[0]});
            mergeContacts.execute();
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM Contact WHERE N_mero_de_Documento__c =: CONTACT_DOCUMENT_NUMBER], 'Merge proccess don´t completed');
    }

    @IsTest
    static void checkMassDuplicateAndmastersContactOk(){

        //Create tow list of contacts with same document number
        //First list
        List<Contact> contacts1 = new List<Contact>();
        for(Integer i = 0; i < 10; i++){
            Contact c = PrepareTestData.createContact(CONTACT_LAST_NAME_2 + '_' + 1);
            c.N_mero_de_Documento__c = CONTACT_DOCUMENT_NUMBER_2;
            contacts1.add(c);
        }

        //Second list
        List<Contact> contacts2 = new List<Contact>();
        for(Integer i = 0; i < 10; i++){
            Contact c = PrepareTestData.createContact(CONTACT_LAST_NAME_3 + '_' + 1);
            c.N_mero_de_Documento__c = CONTACT_DOCUMENT_NUMBER_3;
            contacts2.add(c);
        }

        WorkersManager.avoidAllWorkersExecution(true);
        insert contacts1;
        insert contacts2;
        WorkersManager.avoidAllWorkersExecution(false);

        //Check created contacts with doc number CONTACT_DOCUMENT_NUMBER_2
        System.assertEquals(10, [SELECT Count() FROM Contact WHERE N_mero_de_Documento__c =: CONTACT_DOCUMENT_NUMBER_2], 'Must be return 10 records of the first list');

        //Check created contacts with doc number CONTACT_DOCUMENT_NUMBER_3
        System.assertEquals(10, [SELECT Count() FROM Contact WHERE N_mero_de_Documento__c =: CONTACT_DOCUMENT_NUMBER_3], 'Must be return 10 records of the second list');

        Test.startTest();
            //Send first contact of each list like master of the list
            MergeContactsHelper mergeContacts = new MergeContactsHelper(new List<Contact>{contacts1[0], contacts2[0]});
            mergeContacts.execute();
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM Contact WHERE N_mero_de_Documento__c =: CONTACT_DOCUMENT_NUMBER], 'Merge proccess don´t completed of first list');
        System.assertEquals(1, [SELECT Count() FROM Contact WHERE N_mero_de_Documento__c =: CONTACT_DOCUMENT_NUMBER_3], 'Merge proccess don´t completed of second list');
    }
}