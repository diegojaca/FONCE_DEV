/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 04-06-2022
 * @last modified by  : cesar.parra@s4g.es
**/
@isTest
public with sharing class LeadTDTMTest {
    
    private static final String RECORD_TYPE_PERSON = 'Person';
    private static final Map<String, String> GROUP_MAP = new Map<String, String>{'Comunidad de Madrid' => 'Madrid'};
    private static final String STATE = 'Comunidad de Madrid';

    @TestSetup
    static void setup(){
        PrepareTestData.prepareTestEnvironment();
    }
    
    @IsTest
    static void assignmentRuleTest(){

        Lead personLead = PrepareTestData.createLead('Test', 'Individuo', LeadTDTMTest.RECORD_TYPE_PERSON);
        personLead.BecaDeInteres__c = 'UNIDIVERSIDAD';
        personLead.ComunidadAutonoma__c = LeadTDTMTest.STATE;

        Test.startTest();
        insert personLead;
        Test.stopTest();

        String groupId = [SELECT Id FROM Group WHERE DeveloperName = :LeadTDTMTest.GROUP_MAP.get(LeadTDTMTest.STATE)].get(0).Id;

        System.assertEquals(groupId, [SELECT OwnerId FROM Lead WHERE Id = :personLead.Id].get(0).OwnerId);
    }
}