/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 06-02-2022
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
**/
@IsTest(SeeAllData = true)
public with sharing class LightningLoginFormControllerTest {

 @IsTest
 static void LightningLoginFormControllerInstantiation() {
  LightningLoginFormController controller = new LightningLoginFormController();
  System.assertNotEquals(controller, null);
 }

 @IsTest
 static void testIsUsernamePasswordEnabled() {
  System.assertEquals(true, LightningLoginFormController.getIsUsernamePasswordEnabled());
 }

 @IsTest
 static void testIsSelfRegistrationEnabled() {
  System.assertEquals(false, LightningLoginFormController.getIsSelfRegistrationEnabled());
 }

 @IsTest
 static void testGetSelfRegistrationURL() {
  System.assertEquals(null, LightningLoginFormController.getSelfRegistrationUrl());
 }

 @IsTest
 static void testAuthConfig() {
  Auth.AuthConfiguration authConfig = LightningLoginFormController.getAuthConfig();
  System.assertNotEquals(null, authConfig);
 }

 @IsTest
 static void loginKO(){

    Test.startTest();
        String result = LightningLoginFormController.login('Test username', 'Test PSW', 'httpTest');
    Test.stopTest();

    System.assertEquals(null, result, 'Must be null');
 }

 @IsTest
 static void setExperienceIdNull(){

    Test.startTest();
        String result = LightningLoginFormController.setExperienceId(null);
    Test.stopTest();

    System.assertEquals(null, result, 'Must be null');
 }

 @IsTest
 static void setExperienceId(){

    Test.startTest();
        String result = LightningLoginFormController.setExperienceId('123');
    Test.stopTest();

    System.assertNotEquals(null, result, 'Must be not null');
 }
}