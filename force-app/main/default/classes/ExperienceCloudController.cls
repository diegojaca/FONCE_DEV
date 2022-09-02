/**
 * @description This class will provide methods to LWC that are used in experiences
 * @author bruno.martin@s4g.es
 * @version 07/07/2022
 */
public with sharing class ExperienceCloudController {

    /**
     * @description This method will query all leads that the user can access to
     * @return Leads queried
     */
    @AuraEnabled(Cacheable=false)
    public static List<Lead> getLeadsByOwner(String type) {
        return [SELECT Id, Name, N_mero_de_Documento__c, BecaDeInteres__c FROM Lead WHERE BecaDeInteres__c = :type AND IsConverted = FALSE WITH SECURITY_ENFORCED ORDER BY Name];
    }

}