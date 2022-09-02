/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 06-23-2022
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
**/
@isTest
public with sharing class MaxRequestsForParentWorkerTest {

    private static final String NAME_ACCOUNT = 'Test';  
    private static final String LAST_NAME_CONTACT = 'Test Last Name';  

    @TestSetup
    static void setup(){
        PrepareTestData.prepareTestEnvironment();

        Account account = PrepareTestData.createAccount(MaxRequestsForParentWorkerTest.NAME_ACCOUNT);
        insert account;

        Contact contact = PrepareTestData.createContact(LAST_NAME_CONTACT);
        insert contact;

        outfunds__Funding_Program__c fundingProgram = PrepareTestData.createFundingPrograms(1).get(0);
        fundingProgram.outfunds__Status__c = 'In progress';
        fundingProgram.IsForUniversity__c = true;
        insert fundingProgram;
        
        List<outfunds__Funding_Request__c> fundingRequests = new List<outfunds__Funding_Request__c>();

        outfunds__Funding_Request__c fundingRequest = PrepareTestData.createFundingRequests(fundingProgram.Id, 1).get(0);
        fundingRequest.outfunds__Status__c = 'In progress';
        fundingRequest.outfunds__Applying_Organization__c = account.Id;
        fundingRequests.add(fundingRequest);

        outfunds__Funding_Request__c fundingRequestWithContact = PrepareTestData.createFundingRequests(fundingProgram.Id, 1).get(0);
        fundingRequestWithContact.outfunds__Status__c = 'In progress';
        fundingRequestWithContact.outfunds__Applying_Contact__c = contact.Id;
        fundingRequests.add(fundingRequestWithContact);

        insert fundingRequests;
    }
    
    @IsTest
    static void maxRequestsForUniversityTest(){       
        MaxRequestsForParentWorker worker =new MaxRequestsForParentWorker();

        outfunds__Funding_Program__c fundingProgram = [SELECT Id FROM outfunds__Funding_Program__c LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];  
        
        System.assertEquals(1, [SELECT Count() FROM outfunds__Funding_Request__c WHERE outfunds__FundingProgram__c = :fundingProgram.Id AND outfunds__Applying_Organization__c = :account.Id]);

        String msg;
        outfunds__Funding_Request__c fundingRequest = PrepareTestData.createFundingRequests(fundingProgram.Id, 1).get(0);
        fundingRequest.outfunds__Status__c = 'In progress';
        fundingRequest.outfunds__Applying_Organization__c = account.Id;

        worker.bulkBeforeInsert(new List<outfunds__Funding_Request__c>{fundingRequest});

        Test.startTest();        
        worker.beforeInsert(fundingRequest);
        Test.stopTest();

        System.assertEquals(fundingRequest.getErrors().get(0).getMessage(),'Ya hay otra solicitud para este programa.');
    }

    @IsTest
    static void maxRequestsForContactTest(){       
        MaxRequestsForParentWorker worker =new MaxRequestsForParentWorker();

        outfunds__Funding_Program__c fundingProgram = [SELECT Id FROM outfunds__Funding_Program__c LIMIT 1];
        Contact contact = [SELECT Id FROM Contact LIMIT 1];  
        
        System.assertEquals(1, [SELECT Count() FROM outfunds__Funding_Request__c WHERE outfunds__FundingProgram__c = :fundingProgram.Id AND outfunds__Applying_Contact__c = :contact.Id]);

        String msg;
        outfunds__Funding_Request__c fundingRequest = PrepareTestData.createFundingRequests(fundingProgram.Id, 1).get(0);
        fundingRequest.outfunds__Status__c = 'In progress';
        fundingRequest.outfunds__Applying_Contact__c = contact.Id;

        worker.bulkBeforeInsert(new List<outfunds__Funding_Request__c>{fundingRequest});

        Test.startTest();        
            worker.beforeInsert(fundingRequest);
        Test.stopTest();

        System.assertEquals(fundingRequest.getErrors().get(0).getMessage(),'Ya hay otra solicitud para este programa.');
        System.assertEquals(1, [SELECT Count() FROM outfunds__Funding_Request__c WHERE outfunds__FundingProgram__c = :fundingProgram.Id AND outfunds__Applying_Contact__c = :contact.Id]);
    }

    @IsTest
    static void maxRequestsForContacttalentoDigitalTest(){       
        MaxRequestsForParentWorker worker =new MaxRequestsForParentWorker();

        outfunds__Funding_Program__c fundingProgram = [SELECT Id FROM outfunds__Funding_Program__c LIMIT 1];
        fundingProgram.Tipo_de_Programas_de_Becas__c = CONSTANTS.FOR_DIGITAL_TALENT;
        update fundingProgram;

        Contact contact = [SELECT Id FROM Contact LIMIT 1];  
        
        System.assertEquals(1, [SELECT Count() FROM outfunds__Funding_Request__c WHERE outfunds__FundingProgram__c = :fundingProgram.Id AND outfunds__Applying_Contact__c = :contact.Id]);

        String msg;
        outfunds__Funding_Request__c fundingRequest = PrepareTestData.createFundingRequests(fundingProgram.Id, 1).get(0);
        fundingRequest.outfunds__Status__c = 'In progress';
        fundingRequest.outfunds__Applying_Contact__c = contact.Id;
        insert fundingRequest;

        worker.bulkBeforeInsert(new List<outfunds__Funding_Request__c>{fundingRequest});

        Test.startTest();        
            worker.beforeInsert(fundingRequest);
        Test.stopTest();

        System.assertEquals(2, [SELECT Count() FROM outfunds__Funding_Request__c WHERE outfunds__FundingProgram__c = :fundingProgram.Id AND outfunds__Applying_Contact__c = :contact.Id]);
    }
}