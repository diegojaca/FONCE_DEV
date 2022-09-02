/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 09-02-2022
 * @last modified by  : diego.jacanamijoy@s4g.es
**/
@Istest
public with sharing class MaxRequestsForAmountWorkerTest {

    private static final String LAST_NAME_CONTACT = 'Test LastName';
    
    @TestSetup
    static void makeData(){
        
        PrepareTestData.prepareTestEnvironment();

        Contact contact = PrepareTestData.createContact(LAST_NAME_CONTACT);
        insert contact;

        outfunds__Funding_Program__c fundingProgram = PrepareTestData.createFundingPrograms(1).get(0);
        fundingProgram.outfunds__Status__c = 'In progress';
        fundingProgram.Tipo_de_Programas_de_Becas__c = CONSTANTS.FOR_DIGITAL_TALENT;
        insert fundingProgram;

        List<outfunds__Funding_Request__c> fundingRequestsWithContact = PrepareTestData.createFundingRequests(fundingProgram.Id, 9);
        for(outfunds__Funding_Request__c request: fundingRequestsWithContact){

            request.outfunds__Status__c = 'In progress';
            request.outfunds__Applying_Contact__c = contact.Id;
            request.outfunds__Awarded_Amount__c = 1000;
        }
        

        insert fundingRequestsWithContact;
    }

    @IsTest
    static void maxRequestsForContactTest(){       
        MaxRequestsForAmountWorker worker = new MaxRequestsForAmountWorker();

        outfunds__Funding_Program__c fundingProgram = [SELECT Id FROM outfunds__Funding_Program__c LIMIT 1];
        Contact contact = [SELECT Id FROM Contact LIMIT 1];  
        
        System.assertEquals(9, [SELECT Count() FROM outfunds__Funding_Request__c WHERE outfunds__FundingProgram__c = :fundingProgram.Id AND outfunds__Applying_Contact__c = :contact.Id]);

        outfunds__Funding_Request__c fundingRequest = PrepareTestData.createFundingRequests(fundingProgram.Id, 1).get(0);
        fundingRequest.outfunds__Status__c = 'In progress';
        fundingRequest.outfunds__Applying_Contact__c = contact.Id;
        fundingRequest.outfunds__Awarded_Amount__c = 1000;

        worker.bulkBeforeInsert(new List<outfunds__Funding_Request__c>{fundingRequest});

        Test.startTest();        
            worker.beforeInsert(fundingRequest);
        Test.stopTest();

        System.assertEquals(fundingRequest.getErrors().get(0).getMessage(),String.format(Label.MAX_TOTAL_REQUEST_AMOUNT_BY_PROGRAM_MESSAGE, new List<Decimal>{CONSTANTS.MAX_TOTAL_REQUEST_AMOUNT_BY_PROGRAM}));
    }

    @IsTest
    static void maxRequestsForContactUpdateTest(){       
        MaxRequestsForAmountWorker worker = new MaxRequestsForAmountWorker();

        outfunds__Funding_Program__c fundingProgram = [SELECT Id FROM outfunds__Funding_Program__c LIMIT 1];
        Contact contact = [SELECT Id FROM Contact LIMIT 1];  
        
        System.assertEquals(9, [SELECT Count() FROM outfunds__Funding_Request__c WHERE outfunds__FundingProgram__c = :fundingProgram.Id AND outfunds__Applying_Contact__c = :contact.Id]);

        outfunds__Funding_Request__c fundingRequestOld = [SELECT outfunds__Awarded_Amount__c, outfunds__FundingProgram__c, outfunds__Applying_Contact__c FROM outfunds__Funding_Request__c WHERE outfunds__FundingProgram__c = :fundingProgram.Id AND outfunds__Applying_Contact__c = :contact.Id LIMIT 1];
        outfunds__Funding_Request__c fundingRequestNew = fundingRequestOld.clone(true);
        fundingRequestNew.outfunds__Awarded_Amount__c = 2000;

        worker.oldRecordsMap.put(fundingRequestOld.Id, fundingRequestOld);
        worker.bulkBeforeUpdate(new List<outfunds__Funding_Request__c>{fundingRequestOld}, new List<outfunds__Funding_Request__c>{fundingRequestNew});

        Test.startTest();        
            worker.beforeUpdate(fundingRequestOld, fundingRequestNew);
        Test.stopTest();

        System.assertEquals(fundingRequestNew.getErrors().get(0).getMessage(),String.format(Label.MAX_TOTAL_REQUEST_AMOUNT_BY_PROGRAM_MESSAGE, new List<Decimal>{CONSTANTS.MAX_TOTAL_REQUEST_AMOUNT_BY_PROGRAM}));
    }
}