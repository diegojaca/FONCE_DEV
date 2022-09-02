/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 06-02-2022
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
**/
@IsTest
public with sharing class WorkersManagerTest {

    private static final String  TEST_ACCOUNT_NAME = 'test accName';
    private static final String TEST_CIF_DOCUMENT = 'N7311397I';

    @TestSetup
    static void makeData(){
        
        insert PrepareTestData.createHandler(String.valueOf(Account.class), String.valueOf(FieldValidationTDTM.class));
    }

    @IsTest
    static void insertTestOk(){

        Account account = PrepareTestData.createAccount(TEST_ACCOUNT_NAME);
        account.N_mero_de_Documento__c = TEST_CIF_DOCUMENT;

        Test.startTest();
            insert account;
        Test.stopTest();

        System.assertNotEquals(null, account.Id, 'Must be not null');
    }

    @IsTest
    static void updateTestOk(){

        Account account = PrepareTestData.createAccount(TEST_ACCOUNT_NAME);
        account.N_mero_de_Documento__c = TEST_CIF_DOCUMENT;

        WorkersManager.avoidAllWorkersExecution(true);
        insert account;
        WorkersManager.avoidAllWorkersExecution(false);

        account.Name = 'Test modified name';

        Test.startTest();
            update account;
        Test.stopTest();

        System.assertEquals('Test modified name', [SELECT Name FROM Account LIMIT 1].Name, 'The name has not changed');
    }

    @IsTest
    static void deleteTestOk(){

        Account account = PrepareTestData.createAccount(TEST_ACCOUNT_NAME);
        account.N_mero_de_Documento__c = TEST_CIF_DOCUMENT;

        WorkersManager.avoidAllWorkersExecution(true);
        insert account;
        WorkersManager.avoidAllWorkersExecution(false);

        Test.startTest();
            delete account;
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM Account], 'Account isn´t deleted');
    }

    @IsTest
    static void undeleteTestOk(){

        Account account = PrepareTestData.createAccount(TEST_ACCOUNT_NAME);
        account.N_mero_de_Documento__c = TEST_CIF_DOCUMENT;

        WorkersManager.avoidAllWorkersExecution(true);
        insert account;
        System.assertNotEquals(null, account.Id, 'Must be not null');
        delete account;
        System.assertEquals(0, [SELECT Count() FROM Account], 'Account isn´t deleted');
        WorkersManager.avoidAllWorkersExecution(false);

        Test.startTest();
            undelete account;
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM Account], 'Account isn´t undeleted');
    }
    
    @IsTest
    static void avoidWorkersExecutionPerObjectOk(){

        Account account = PrepareTestData.createAccount(TEST_ACCOUNT_NAME);
        account.N_mero_de_Documento__c = TEST_CIF_DOCUMENT;

        Test.startTest();
            WorkersManager.avoidWorkersExecutionPerObject('Account', 'FieldValidationTDTM', true);
            insert account;
            WorkersManager.avoidWorkersExecutionPerObject('Account', 'FieldValidationTDTM', false);
        Test.stopTest();

        System.assertNotEquals(null, account.Id, 'Must be not null');
    }

    @IsTest
    static void avoidWorkerExecutionOk(){

        Account account = PrepareTestData.createAccount(TEST_ACCOUNT_NAME);
        account.N_mero_de_Documento__c = TEST_CIF_DOCUMENT;

        Test.startTest();
            WorkersManager.avoidWorkerExecution('FieldValidationTDTM', 'FieldValidationTDTM', true);
            insert account;
            WorkersManager.avoidWorkerExecution('FieldValidationTDTM', 'FieldValidationTDTM', false);
        Test.stopTest();

        System.assertNotEquals(null, account.Id, 'Must be not null');
    }
}