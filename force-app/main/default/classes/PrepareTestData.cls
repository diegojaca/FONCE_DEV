/**
 * @author      S4G
 * @version     1.0
 * @description This class will contain test creation methods
 *
 * Change log:
 */

@IsTest
public class PrepareTestData {

    private static Bypasser__c byPasser = PrepareTestData.getBypasserInstance();

    private static Bypasser__c getBypasserInstance() {
        Bypasser__c byPasser = Bypasser__c.getInstance();
        if (String.isEmpty(byPasser.Id)) {
            insert byPasser;
        }
        return byPasser;
    }

    public static void byPassAutoLaunchedFlows(Boolean disable) {
        PrepareTestData.byPasser.Disable_Autolaunched_Flows__c = disable;
        update PrepareTestData.byPasser;
    }

    public static void prepareTestEnvironment() {
        createTriggerHandlers();
    }

    public static npsp__Trigger_Handler__c createHandler(String objectName, String triggerName, List<String> triggerActions, Integer loadOrder, Boolean isActive) {
        return new npsp__Trigger_Handler__c(
                Name = triggerName,
                npsp__Object__c = objectName,
                npsp__Class__c = triggerName,
                npsp__Trigger_Action__c = String.join(triggerActions, ';'),
                npsp__Load_Order__c = loadOrder,
                npsp__Active__c = isActive,
                npsp__User_Managed__c = true
        );
    }

    public static npsp__Trigger_Handler__c createHandler(String objectName, String triggerName) {
        return createHandler(objectName, triggerName, new String[]{
                'BeforeInsert', 'BeforeUpdate', 'BeforeDelete', 'AfterInsert', 'AfterUpdate', 'AfterDelete', 'AfterUndelete'
        }, 0, true);
    }

    public static npsp__Trigger_Handler__c createHandler(String objectName, String triggerName, Integer order) {
        return createHandler(objectName, triggerName, new String[]{
                'BeforeInsert', 'BeforeUpdate', 'BeforeDelete', 'AfterInsert', 'AfterUpdate', 'AfterDelete', 'AfterUndelete'
        }, order, true);
    }

    public static void createTriggerHandlers() {
        if ([SELECT Id, npsp__Class__c, npsp__Active__c, npsp__Load_Order__c FROM npsp__Trigger_Handler__c ORDER BY npsp__Class__c ASC].size() == 0) {
            insert createNPSP_Handlers();
        }

        insert new npsp__Trigger_Handler__c[]{
                createHandler('Lead', 'LeadTDTM', 0)
        };
    }


    public static npsp__Trigger_Handler__c createNPSP_Handler(String objectName, String triggerName, String triggerActions, Integer loadOrder, Boolean isActive, Boolean isUserManaged) {
        return new npsp__Trigger_Handler__c(
                Name = triggerName,
                npsp__Object__c = objectName,
                npsp__Class__c = triggerName,
                npsp__Trigger_Action__c = triggerActions,
                npsp__Load_Order__c = loadOrder,
                npsp__Active__c = isActive,
                npsp__User_Managed__c = isUserManaged
        );
    }

    public static List<npsp__Trigger_Handler__c> createNPSP_Handlers() {
        List<npsp__Trigger_Handler__c> handlers = new List<npsp__Trigger_Handler__c>();

        return handlers;
    }

    public static Lead createLead(String lastName, String company, String recordType) {
        S4GTestFactory.setDefaultValues(String.valueOf(Lead.class), String.valueOf(Lead.LastName), lastName);
        S4GTestFactory.setDefaultValues(String.valueOf(Lead.class), String.valueOf(Lead.Company), company);
        S4GTestFactory.setDefaultValues(String.valueOf(Lead.class), String.valueOf(Lead.RecordTypeId)
                , Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(recordType).getRecordTypeId());
        return (Lead) S4GTestFactory.createObject(String.valueOf(Lead.class));
    }

    public static Section__c createImageSection() {
        S4GTestFactory.setDefaultValues(String.valueOf(Section__c.class), String.valueOf(Section__c.Description__c), 'Section Demo');
        S4GTestFactory.setDefaultValues(String.valueOf(Section__c.class), String.valueOf(Section__c.Order__c), 2);
        S4GTestFactory.setDefaultValues(String.valueOf(Section__c.class), String.valueOf(Section__c.RecordTypeId), CONSTANTS.SECTION_RT_IMAGE);
        return (Section__c) S4GTestFactory.createObject(String.valueOf(Section__c.class));
    }

    public static ContentVersion createContentVersion() {
        ContentVersion content = new ContentVersion();
        content.Title = 'Header_Picture1';
        content.PathOnClient = '/' + content.Title + '.jpg';
        Blob bodyBlob = Blob.valueOf('Unit Test ContentVersion Body');
        content.VersionData = bodyBlob;
        content.Origin = 'H';
        return content;
    }

    public static ContentDocumentLink createContentDocumentLink(String linkedEntity, String contentDocumentId) {
        S4GTestFactory.setDefaultValues(String.valueOf(ContentDocumentLink.class), String.valueOf(ContentDocumentLink.LinkedEntityId), linkedEntity);
        S4GTestFactory.setDefaultValues(String.valueOf(ContentDocumentLink.class), String.valueOf(ContentDocumentLink.ContentDocumentId), contentDocumentId);
        S4GTestFactory.setDefaultValues(String.valueOf(ContentDocumentLink.class), String.valueOf(ContentDocumentLink.ShareType), 'I');
        S4GTestFactory.setDefaultValues(String.valueOf(ContentDocumentLink.class), String.valueOf(ContentDocumentLink.Visibility), 'AllUsers');
        return (ContentDocumentLink) S4GTestFactory.createObject(String.valueOf(ContentDocumentLink.class));
    }

    public static List<outfunds__Review__c> createParentReviews(String fundingRequestId, Integer quantity) {
        S4GTestFactory.setDefaultValues(String.valueOf(outfunds__Review__c.class), String.valueOf(outfunds__Review__c.outfunds__FundingRequest__c), fundingRequestId);
        return S4GTestFactory.createObjects(String.valueOf(outfunds__Review__c.class), quantity);
    }

    public static List<outfunds__Review__c> createChildReviews(String parentReviewId, Integer quantity) {
        S4GTestFactory.setDefaultValues(String.valueOf(outfunds__Review__c.class), String.valueOf(outfunds__Review__c.ParentReview__c), parentReviewId);
        return S4GTestFactory.createObjects(String.valueOf(outfunds__Review__c.class), quantity);
    }

    public static List<outfunds__Funding_Request__c> createFundingRequests(String fundingProgramId, Integer quantity) {
        S4GTestFactory.setDefaultValues(String.valueOf(outfunds__Funding_Request__c.class), String.valueOf(outfunds__Funding_Request__c.outfunds__FundingProgram__c), fundingProgramId);
        return S4GTestFactory.createObjects(String.valueOf(outfunds__Funding_Request__c.class), quantity);
    }

    public static List<outfunds__Requirement__c> createRequirements(String fundingProgramId, Integer quantity) {
        S4GTestFactory.setDefaultValues(String.valueOf(outfunds__Requirement__c.class), String.valueOf(outfunds__Requirement__c.Funding_Program__c), fundingProgramId);
        return S4GTestFactory.createObjects(String.valueOf(outfunds__Requirement__c.class), quantity);
    }

    public static List<outfunds__Funding_Program__c> createFundingPrograms(Integer quantity) {
        return S4GTestFactory.createObjects(String.valueOf(outfunds__Funding_Program__c.class), quantity);
    }

    public static scoring_criteria__c createScoringCriteriaQuestion(String fundingProgramId, String fieldInReview, String fieldInRequest) {
        S4GTestFactory.setDefaultValues(String.valueOf(scoring_criteria__c.class), String.valueOf(scoring_criteria__c.Programa_de_beca__c), fundingProgramId);
        S4GTestFactory.setDefaultValues(String.valueOf(scoring_criteria__c.class), String.valueOf(scoring_criteria__c.Campo_en_Revision__c), fieldInReview);
        S4GTestFactory.setDefaultValues(String.valueOf(scoring_criteria__c.class), String.valueOf(scoring_criteria__c.campo_en_solicitud__c), fieldInRequest);
        S4GTestFactory.setDefaultValues(String.valueOf(scoring_criteria__c.class), String.valueOf(scoring_criteria__c.RecordTypeId), CONSTANTS.SCORING_CRITERIA_RT_QUESTION);
        return (scoring_criteria__c) S4GTestFactory.createObject(String.valueOf(scoring_criteria__c.class));
    }

    public static scoring_criteria__c createScoringCriteriaResponse(String questionId) {
        S4GTestFactory.setDefaultValues(String.valueOf(scoring_criteria__c.class), String.valueOf(scoring_criteria__c.Criterio_padre__c), questionId);
        S4GTestFactory.setDefaultValues(String.valueOf(scoring_criteria__c.class), String.valueOf(scoring_criteria__c.RecordTypeId), CONSTANTS.SCORING_CRITERIA_RT_RESPONSE);
        return (scoring_criteria__c) S4GTestFactory.createObject(String.valueOf(scoring_criteria__c.class));
    }

    public static List<EmailMessage> createEmailMessage(Integer quantity, Case theCase) {
        S4GTestFactory.setDefaultValues(String.valueOf(EmailMessage.class), String.valueOf(EmailMessage.ParentId), theCase.Id);
        return S4GTestFactory.createObjects(String.valueOf(EmailMessage.class), quantity);
    }

    public static Contact createContact(String lastName) {
        S4GTestFactory.setDefaultValues(String.valueOf(Contact.class), String.valueOf(Contact.LastName), lastName);
        return (Contact) S4GTestFactory.createObject(String.valueOf(Contact.class));
    }

    public static Account createAccount(String name) {
        S4GTestFactory.setDefaultValues(String.valueOf(Account.class), String.valueOf(Account.Name), name);
        return (Account) S4GTestFactory.createObject(String.valueOf(Account.class));
    }

    public static List<String> getRollUpDefinitionChildFieldsToBeQueried(String sObjectApiName) {
        Map<String, RollupDefinition__mdt> rollUpDefinitionByDeveloperName = RollupDefinition__mdt.getAll();
        List<String> fieldsToBeQueried = new List<String>();
        for (RollupDefinition__mdt rollupDefinition : rollUpDefinitionByDeveloperName.values()) {
            if (rollupDefinition.ChildObject__c.equals(sObjectApiName) && String.isNotBlank(rollupDefinition.FilterField__c)) {
                fieldsToBeQueried.add(rollupDefinition.FilterField__c);
            }
        }
        return fieldsToBeQueried;
    }

    public static List<Recurso__c> createResources(String fundingRequestId, Integer quantity) {
        S4GTestFactory.setDefaultValues(String.valueOf(Recurso__c.class), String.valueOf(Recurso__c.Funding_Request__c), fundingRequestId);
        return S4GTestFactory.createObjects(String.valueOf(Recurso__c.class), quantity);
    }

    public static List<Objective__c> createObjectives(String fundingRequestId, Integer quantity) {
        S4GTestFactory.setDefaultValues(String.valueOf(Objective__c.class), String.valueOf(Objective__c.Funding_Request__c), fundingRequestId);
        return S4GTestFactory.createObjects(String.valueOf(Objective__c.class), quantity);
    }

    public static User createUser(String email, String profileId) {

        User u = new user();
        u.LastName = 'Test Code';
        u.Email = email;
        u.Alias = 'Tcode';
        u.Username = Integer.valueOf(MAth.random() * 10 + Math.random()) + '_Test' + System.now().millisecond() + '@test.com';
        u.CommunityNickname = Integer.valueOf(MAth.random() * 10 + Math.random()) + '_Test' + System.now().millisecond() + '@test.com';
        u.LocaleSidKey = 'en_US';
        u.TimeZoneSidKey = 'GMT';
        u.ProfileID = profileId;
        u.LanguageLocaleKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        return u;
    }

    public static List<pmdm__Program__c> createPrograms(Integer quantity) {
        return S4GTestFactory.createObjects(String.valueOf(pmdm__Program__c.class), quantity);
    }

    public static List<pmdm__Service__c> createServices(String programId, Integer quantity) {
        S4GTestFactory.setDefaultValues(String.valueOf(pmdm__Service__c.class), String.valueOf(pmdm__Service__c.pmdm__Program__c), programId);
        // S4GTestFactory.setDefaultValues(String.valueOf(pmdm__Service__c.class), String.valueOf(pmdm__Service__c.Objective__c), objectiveId);
        return S4GTestFactory.createObjects(String.valueOf(pmdm__Service__c.class), quantity);
    }

    public static List<pmdm__ProgramEngagement__c> createProgramEngagements(String programId, String contactId, Integer quantity) {
        S4GTestFactory.setDefaultValues(String.valueOf(pmdm__ProgramEngagement__c.class), String.valueOf(pmdm__ProgramEngagement__c.pmdm__Program__c), programId);
        S4GTestFactory.setDefaultValues(String.valueOf(pmdm__ProgramEngagement__c.class), String.valueOf(pmdm__ProgramEngagement__c.pmdm__Contact__c), contactId);
        return S4GTestFactory.createObjects(String.valueOf(pmdm__ProgramEngagement__c.class), quantity);
    }

    public static List<pmdm__ServiceDelivery__c> createServiceDeliveries(String programEngagementId, String serviceId, Integer quantity) {
        S4GTestFactory.setDefaultValues(String.valueOf(pmdm__ServiceDelivery__c.class), String.valueOf(pmdm__ServiceDelivery__c.pmdm__ProgramEngagement__c), programEngagementId);
        S4GTestFactory.setDefaultValues(String.valueOf(pmdm__ServiceDelivery__c.class), String.valueOf(pmdm__ServiceDelivery__c.pmdm__Service__c), serviceId);
        return S4GTestFactory.createObjects(String.valueOf(pmdm__ServiceDelivery__c.class), quantity);
    }

}