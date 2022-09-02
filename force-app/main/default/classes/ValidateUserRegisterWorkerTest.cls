/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 06-13-2022
 * @last modified by  : diego.jacanamijoy@s4g.es
**/
@IsTest
public with sharing class ValidateUserRegisterWorkerTest {

    private static final String USER_EMAIL = 'test@test.com';
    private static final String USER_EMAIL_2 = 'test@test2.com';
    private static final String USER_CIF = '12345TEST';
    private static final String USER_CIF_2 = '54321TEST';
    private static final String  CONTACT_LAST_NAME = 'test lastname';
    private static final String PROFILE_LIKE_NAME_PORTAL = 'Gestor %';
    private static final String EMAIL_LABEL = 'Email';
    private static final String DOCUMENT_NUMBER_LABEL = 'Número de documento';
    
    @TestSetup
    static void makeData(){

        Profile profile = [SELECT Id FROM Profile WHERE Name LIKE :PROFILE_LIKE_NAME_PORTAL LIMIT 1];

        User user = PrepareTestData.createUser(USER_EMAIL, profile.Id);
        user.N_mero_de_Documento__c = USER_CIF;
        
        WorkersManager.avoidAllWorkersExecution(true);
        insert user;
        WorkersManager.avoidAllWorkersExecution(false);

        insert PrepareTestData.createHandler(String.valueOf(User.class), String.valueOf(ValidateUserRegisterWorker.class));
    }

    @IsTest
    static void duplicateCIFUserKO(){

        //Check current user
        List<User> existUsers = [SELECT Id FROM User WHERE N_mero_de_Documento__c =: USER_CIF];
        System.assertEquals(1, existUsers.size(), 'There must be only one user');

        //Get profile to new user
        Profile profile = [SELECT Name FROM Profile WHERE Name LIKE :PROFILE_LIKE_NAME_PORTAL LIMIT 1];

        //New user
        User user = PrepareTestData.createUser(USER_EMAIL_2, profile.Id);
        user.N_mero_de_Documento__c = USER_CIF;

        //Format expected error message
        List<String> params = new List<String>{DOCUMENT_NUMBER_LABEL, USER_CIF, user.N_mero_de_Documento__c, user.Email, Profile.Name, existUsers[0].Id};
        String formatedText = String.format(Label.REGISTER_DUPLICATE_ERROR, params);

        Test.startTest();
            try {
                insert user;    
            } catch (Exception e) {
                System.assertEquals(true, e.getMessage().contains(formatedText), 'It´s not the controlled error');
            }
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM User WHERE N_mero_de_Documento__c =: USER_CIF], 'Must be return one user');
    }

    @IsTest
    static void duplicateEmailUserKO(){

        //Check current user
        List<User> existUsers = [SELECT Id FROM User WHERE Email =: USER_EMAIL];
        System.assertEquals(1, existUsers.size(), 'There must be only one user');

        //Get profile to new user
        Profile profile = [SELECT Name FROM Profile WHERE Name LIKE :PROFILE_LIKE_NAME_PORTAL LIMIT 1];

        //New user
        User user = PrepareTestData.createUser(USER_EMAIL, profile.Id);
        user.N_mero_de_Documento__c = USER_CIF_2;

        //Format expected error message
        List<String> params = new List<String>{EMAIL_LABEL, USER_EMAIL, user.N_mero_de_Documento__c, user.Email, Profile.Name, existUsers[0].Id};
        String formatedText = String.format(Label.REGISTER_DUPLICATE_ERROR, params);

        Test.startTest();
            try {
                insert user;    
            } catch (Exception e) {
                System.assertEquals(true, e.getMessage().contains(formatedText), 'It is not the controlled error');
            }
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM User WHERE Email =: USER_EMAIL], 'Must be return one user');
    }

    @IsTest
    static void duplicateCIFUserOk(){

        //Check current user
        List<User> existUsers = [SELECT Id FROM User WHERE Email =: USER_EMAIL_2 OR N_mero_de_Documento__c =: USER_CIF_2];
        System.assertEquals(0, existUsers.size(), 'There should be no user');

        //Get profile to new user
        Profile profile = [SELECT Name FROM Profile WHERE Name LIKE :PROFILE_LIKE_NAME_PORTAL LIMIT 1];

        //New user
        User user = PrepareTestData.createUser(USER_EMAIL_2, profile.Id);
        user.N_mero_de_Documento__c = USER_CIF_2;

        Test.startTest();
            insert user;
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM User WHERE N_mero_de_Documento__c =: USER_CIF_2 AND Email =: USER_EMAIL_2], 'Must be return 1 users');
    }

    @IsTest
    static void createComunityUser(){

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs (thisUser) {

            WorkersManager.avoidAllWorkersExecution(true);
            //Create portal account owner
            UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
            Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator' OR Name = 'Administrador del Sistema'];

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

            User user1 = PrepareTestData.createUser(USER_EMAIL_2, portalProfile.Id);
            user1.N_mero_de_Documento__c = USER_CIF_2;
            user1.ContactId = contact.Id;

            Test.startTest();
                Database.insert(user1);
            Test.stopTest();

            System.assertEquals(1, [SELECT Count() FROM User WHERE ContactId <> null AND N_mero_de_Documento__c =: USER_CIF_2], 'Must be return 1 users');
            System.assertEquals(1, [SELECT Count() FROM Contact ], 'Must be return 1 contact');
        }
    }

}