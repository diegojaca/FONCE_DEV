/**
 * @description 
 * @author bruno.martin@s4g.es
 * @version 07/07/2022
 */
@IsTest
private class ExperienceCloudControllerTest {

    private static final String LEAD_LAST_NAME = 'Test Lead lastName';
    private static final String LEAD_INDIVIDUAL_COMPANY = 'Individuo';
    private static final String LEAD_PERSON_RT = 'Person';

    @TestSetup
    static void prepareData() {
        //Insert Lead
        Lead lead = PrepareTestData.createLead(LEAD_LAST_NAME, LEAD_INDIVIDUAL_COMPANY, LEAD_PERSON_RT);
        lead.BecaDeInteres__c = 'UNIDIVERSIDAD';
        insert lead;
    }

    @IsTest
    static void testGetLeadsByOwner() {
        List<Lead> queryLeads = ExperienceCloudController.getLeadsByOwner('UNIDIVERSIDAD');
        System.assertEquals(1, queryLeads.size(), 'Should have retrieved that lead');
    }
}