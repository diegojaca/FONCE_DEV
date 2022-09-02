/**
 * @description All static constants must come here to be reused across all code
 * @author bruno.martin@s4g.es
 * @version 08/04/2022
 */
public with sharing class CONSTANTS {

    //outfunds__Funding_Request__c
    public static final String FUNDING_REQUEST_STATUS_IN_PROGRESS = 'In progress';
    public static final String FUNDING_REQUEST_STATUS_REVIEWED = 'Reviewed';
    public static final String FUNDING_REQUEST_STATUS_ACCEPTED = 'Aceptada';
    public static final String FUNDING_REQUEST_STATUS_AWARDED = 'Awarded';
    public static final String FUNDING_REQUEST_REVIEW_STATUS_GRANTED = 'Concedida';

    //Section__c
    public static final String SECTION_RT_IMAGE = Schema.SObjectType.Section__c.getRecordTypeInfosByDeveloperName().get('Imagen').getRecordTypeId();
    public static final String SECTION_RT_MAIN = Schema.SObjectType.Section__c.getRecordTypeInfosByDeveloperName().get('Principal').getRecordTypeId();

    //AssignmentRules
    public static final String ASSIGNMENT_RULE_NAME = 'UniversityAssignmentRule';

    //scoring_criteria__c
    public static final String SCORING_CRITERIA_RT_QUESTION = Schema.SObjectType.scoring_criteria__c.getRecordTypeInfosByDeveloperName().get('Pregunta').getRecordTypeId();
    public static final String SCORING_CRITERIA_RT_RESPONSE = Schema.SObjectType.scoring_criteria__c.getRecordTypeInfosByDeveloperName().get('Respuesta').getRecordTypeId();

    //outfunds__Requirement__c
    public static final String REQUIREMENT_RT_REQUIRE_DOCUMENT = Schema.SObjectType.outfunds__Requirement__c.getRecordTypeInfosByDeveloperName().get('RequiredDocument').getRecordTypeId();
    public static final String REQUIREMENT_CATEGORY_PROJECT_REQUIREMENT = 'Requisito de Proyecto';

    //User
    public static final List<String> COMMUNITY_USER_TYPES = new List<String>{
            'PowerPartner'
            , 'CSPLitePortal'
            , 'CustomerSuccess'
            , 'PowerCustomerSuccess'
            , 'Guest'
    };

    //outfunds__Review__c
    public static final String REVIEW_STATUS_NOT_STARTED = 'Not Started';
    public static final String REVIEW_STATUS_IN_PROGRESS = 'In Progress';
    public static final String REVIEW_STATUS_SUBMITTED = 'Submitted';
    public static final String REVIEW_STATUS_REVISED = 'Revisada';

    //Scholarships Program types (outfunds__Funding_Program__c.Tipo_de_Programas_de_Becas__c)
    public static final String FOR_DIGITAL_TALENT = 'POR TALENTO DIGITAL';
    public static final String CRUE_PRACTICES = 'PRÁCTICAS “FUNDACIÓN ONCE-CRUE” UNIVERSIDADES';

    //Max total request amount by program
    public static final Decimal MAX_TOTAL_REQUEST_AMOUNT_BY_PROGRAM = 10000;

    //pmdm__Program__c
    public static final String PROGRAM_STATUS_ACTIVE = 'Active';
    public static final String PROGRAM_STATUS_COMPLETED = 'Completed';

}