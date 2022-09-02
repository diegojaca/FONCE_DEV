/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 07-22-2022
 * @last modified by  : cesar.parra@s4g.es
**/
@IsTest
public with sharing class LeadConversionManagerTest {

    private static final String  TEST_ACCOUNT_NAME = 'test accName';
    private static final String RECORD_TYPE_PERSON = 'Person';
    private static final String STATE = 'Comunidad de Madrid';
    private static final String  DOC_NUMBER_EXT_ID = '123456789';
    private static final String  TEST_LASTNAME = 'test lastname';
    
    @TestSetup
    static void makeData(){

        Account account = PrepareTestData.createAccount(TEST_ACCOUNT_NAME);
        insert account;

        Contact contact = PrepareTestData.createContact(TEST_LASTNAME);
        contact.N_mero_de_Documento__c = DOC_NUMBER_EXT_ID;
        contact.AccountId = account.Id;
        insert contact;
        
        Lead personLead = PrepareTestData.createLead('Test', 'Individuo', RECORD_TYPE_PERSON);
        personLead.BecaDeInteres__c = 'UNIDIVERSIDAD';
        personLead.ComunidadAutonoma__c = STATE;
        personLead.N_mero_de_Documento__c = DOC_NUMBER_EXT_ID;
        insert personLead;

    }

    @IsTest
    static void processMappingOK(){

        //PrepareTestData.createTriggerHandlers();

        List<String> leadFields = new List<String>();

        for(Mapping_Definition__mdt mapingCnf: [SELECT SourceField__c FROM Mapping_Definition__mdt WHERE TargetObject__c = 'Contact' AND SourceObject__c = 'Lead']){
            leadFields.add(mapingCnf.SourceField__c);
        }

        String query = 'SELECT {0}, OwnerId FROM Lead';
        query = String.format(query, new List<String>{String.join(leadFields, ',')});
        List<Lead> leads = Database.query(query);

        Test.startTest();
            String contactId = LeadConversionManager.convertUniqueLead(leads.get(0));
        Test.stopTest();

        System.assertEquals(true, [SELECT IsConverted FROM Lead LIMIT 1].IsConverted, 'Must be Lead converted');
        System.assertEquals(contactId, [SELECT Id FROM Contact].get(0).Id, 'Must be Lead converted');
    }
}