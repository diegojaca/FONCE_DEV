/**
 * @description       : 
 * @author            : diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 06-13-2022
 * @last modified by  : diego.jacanamijoy@s4g.es
**/
@IsTest
public with sharing class UserDataToContactWorkerTest {

    private static final String  CONTACT_LAST_NAME = 'test lastname';
    private static final String USER_EMAIL = 'test@test.com';
    private static final String USER_DNI = '12345TEST';

    @TestSetup
    static void makeData(){
        
        insert PrepareTestData.createHandler(String.valueOf(User.class), String.valueOf(UserDataToContactWorker.class));

        insert PrepareTestData.createHandler(String.valueOf(Contact.class), 'ACCT_IndividualAccounts_TDTM');
    }

    @IsTest
    static void createComunityUser(){

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs (thisUser) {

            WorkersManager.avoidAllWorkersExecution(true);
            //Create portal account owner
            UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
            Profile profile1 = [Select Id from Profile where name IN ('System Administrator', 'Administrador del sistema')];

            User portalAccountOwner1 = PrepareTestData.createUser('adminAccount@test.com', profile1.Id);
            portalAccountOwner1.UserRoleId = portalRole.Id;
            Database.insert(portalAccountOwner1);

            //Create account
            Account act = new Account(
                Name = 'Test Ac Name',
                OwnerId = portalAccountOwner1.id
            );
            Database.insert(act);

            //Create contact
            Contact contact = PrepareTestData.createContact(CONTACT_LAST_NAME);
            contact.AccountId = act.Id;
            Database.insert(contact);
            WorkersManager.avoidAllWorkersExecution(false);

            //Create Portal User
            Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'Portal de Becas - Login' Limit 1];

            User user1 = PrepareTestData.createUser(USER_EMAIL, portalProfile.Id);
            user1.N_mero_de_Documento__c = USER_DNI;
            user1.ContactId = contact.Id;

            System.assertEquals(1, [SELECT Count() FROM Contact ], 'Must be return one record');
            System.assertEquals(null, [SELECT N_mero_de_Documento__c FROM Contact LIMIT 1].N_mero_de_Documento__c, 'Must be return null');

            Test.startTest();
                Database.insert(user1);
            Test.stopTest();

            List<Contact> contacts = [SELECT AccountId, Consultar_duplicados__c FROM Contact WHERE N_mero_de_Documento__c =: USER_DNI];

            System.assertEquals(1, [SELECT Count() FROM User WHERE ContactId <> null AND N_mero_de_Documento__c =: USER_DNI], 'Must be return 1 users');
            System.assertEquals(1, contacts.size(), 'Must be return 1 Contact');
            System.assertNotEquals(act.Id, contacts[0].AccountId, 'Related account, isn`t updated');
            System.assertEquals(true, contacts[0].Consultar_duplicados__c, 'Contact isn´t updated');
        }
    }
}