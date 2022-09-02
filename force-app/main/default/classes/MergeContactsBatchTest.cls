/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 06-10-2022
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
**/
@IsTest
public with sharing class MergeContactsBatchTest {

    private static final String CONTACT_LAST_NAME = 'Test lastname' ;
    private static final String CONTACT_LAST_NAME_2 = 'Test lastname_2' ;
    private static final String CONTACT_DOCUMENT_NUMBER = 'F21065800' ;
    private static final String USER_EMAIL = 'test@test.com';
    private static final String PROFILE_LIKE_NAME_PORTAL = '%Portal%';
    private static final String CRON_EXP = '0 2 0 ? * * *';
    
    @TestSetup
    static void makeData(){
        
        Contact contact = PrepareTestData.createContact(CONTACT_LAST_NAME);
        contact.N_mero_de_Documento__c = CONTACT_DOCUMENT_NUMBER;

        WorkersManager.avoidAllWorkersExecution(true);
        insert contact;
        WorkersManager.avoidAllWorkersExecution(false);
    }

    @IsTest
    static void checkDuplicateContactOk(){

        System.assertEquals(1, [SELECT Count() FROM Contact WHERE N_mero_de_Documento__c =: CONTACT_DOCUMENT_NUMBER], 'Must be return one record');

        //Create contact with same document number
        Contact contact = PrepareTestData.createContact(CONTACT_LAST_NAME_2);
        contact.N_mero_de_Documento__c = CONTACT_DOCUMENT_NUMBER;
        Contact.Consultar_duplicados__c = true;

        WorkersManager.avoidAllWorkersExecution(true);
        insert contact;
        WorkersManager.avoidAllWorkersExecution(false);

        System.assertEquals(2, [SELECT Count() FROM Contact WHERE N_mero_de_Documento__c =: CONTACT_DOCUMENT_NUMBER], 'Must be return two records');
        System.assertEquals(1, [SELECT Count() FROM Contact WHERE Consultar_duplicados__c = true], 'Must be return one records to validate duplicates');

        Test.startTest();
            MergeContactsBatch mergebatch = new MergeContactsBatch();
            ID batchprocessid = Database.executeBatch(mergebatch);
        Test.stopTest();

        
        System.assertEquals(1, [SELECT Count() FROM Contact WHERE N_mero_de_Documento__c =: CONTACT_DOCUMENT_NUMBER], 'Merge proccess don´t completed');
        System.assertEquals(0, [SELECT Count() FROM Contact WHERE Consultar_duplicados__c = true], 'Must be return 0 records to validate duplicates');
    }

    @IsTest
    static void checkBulkDuplicateContactOk(){

        String DOCUMENT_NUMBER_TEST = 'ABC12345';

        //Create 10 lists of 10 contacts with the same document number
        List<Contact> contacts = new List<Contact>();
        
        for (Integer i = 0; i < 10; i++) {
            for(Integer j = 0; j < 10; j++){

                Contact contact = PrepareTestData.createContact(CONTACT_LAST_NAME_2 + i + '_' + j);
                contact.N_mero_de_Documento__c = DOCUMENT_NUMBER_TEST + i;
                contact.Consultar_duplicados__c = j == 0;
                contacts.add(contact);
            }
        }

        WorkersManager.avoidAllWorkersExecution(true);
        insert contacts;
        WorkersManager.avoidAllWorkersExecution(false);

        System.assertEquals(100, [SELECT Count() FROM Contact WHERE N_mero_de_Documento__c LIKE 'ABC12345%'], 'Must be return 100 records');

        AggregateResult[] groupedResults = [SELECT Count(Id), N_mero_de_Documento__c FROM Contact WHERE N_mero_de_Documento__c LIKE 'ABC12345%' GROUP BY N_mero_de_Documento__c];

        Integer index = 0;
        for (AggregateResult ar : groupedResults)  {
            System.assertEquals(10, ar.get('expr0'), 'Must be return 10 with document number ' + ar.get('N_mero_de_Documento__c'));
            index++;
        }

        System.assertEquals(10, index, 'Must be return 10 groups of contacts by document number');

        List<Contact> masterContacts = [SELECT N_mero_de_Documento__c FROM Contact WHERE Consultar_duplicados__c = true];

        System.assertEquals(10, masterContacts.size(), 'Must be return 10 master contacts');

        Test.startTest();
            MergeContactsBatch.runMe(10);
        Test.stopTest();

        
        System.assertEquals(10, [SELECT Count() FROM Contact WHERE N_mero_de_Documento__c LIKE 'ABC12345%'], 'Must be return 10 records');
        System.assertEquals(0, [SELECT Count() FROM Contact WHERE Consultar_duplicados__c = true], 'Must be return 0 records to validate duplicates');
    }

    @IsTest
    static void checkDuplicateContactScheduleOk(){

        Test.startTest();
            String jobId = System.schedule('TestMergeContactsBatch', CRON_EXP, new MergeContactsBatch());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);

    }
}