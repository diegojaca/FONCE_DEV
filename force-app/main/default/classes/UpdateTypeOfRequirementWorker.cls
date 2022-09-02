/**
 * @description This worker will set type of requirement field in objects in order to filter and show different types of requirements
 * @author bruno.martin@s4g.es
 * @version 27/07/2022
 */
global with sharing class UpdateTypeOfRequirementWorker extends AbstractWorker {

    private SObjectType sObjectType;
    private Map<String, List<String>> typeRequirementsByStatus = new Map<String, List<String>>();
    private Map<SObjectType, String> statusFieldBySObjectType = new Map<SObjectType, String>{
            outfunds__Funding_Request__c.getSObjectType() => String.valueOf(outfunds__Funding_Request__c.outfunds__Status__c)
            , pmdm__Program__c.getSObjectType() => String.valueOf(pmdm__Program__c.pmdm__Status__c)
    };

    global UpdateTypeOfRequirementWorker() {
        super(String.valueOf(UpdateTypeOfRequirementWorker.class));
    }

    public override void bulkBefore(List<SObject> newRecords) {
        this.getTypeRequirementsByFundingRequestStatus(newRecords);
    }

    public override void beforeInsert(SObject so) {
        this.changeTypeRequirementsFromStatus(null, so);
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        this.changeTypeRequirementsFromStatus(oldSo, so);
    }

    /**
    * @description This method will obtain type of requirement to be set using a dependent multipicklist
    * @author s4g | 12-16-2021
    **/
    private void getTypeRequirementsByFundingRequestStatus(List<SObject> newRecords) {
        this.sObjectType = newRecords?.get(0)?.getSObjectType();
        if (this.sObjectType == outfunds__Funding_Request__c.getSObjectType()) {
            this.typeRequirementsByStatus = S4GUtils.getDependentPicklistValues(outfunds__Funding_Request__c.Type_Requirement__c);
        } else if (this.sObjectType == pmdm__Program__c.getSObjectType()) {
            this.typeRequirementsByStatus = S4GUtils.getDependentPicklistValues(pmdm__Program__c.Type_Requirement__c);
        }
    }

    /**
    * @description Update type of requirement based on status field with valid values for that status
    * @author s4g | 12-15-2021
    **/
    private void changeTypeRequirementsFromStatus(SObject oldSo, SObject so) {
        String statusField = this.statusFieldBySObjectType.get(this.sObjectType);
        if (this.sObjectType != null && (oldSo == null || S4GUtils.isChanged(so, oldSo, statusField))
                && this.typeRequirementsByStatus.containsKey((String) so.get(statusField))) {
            so.put('Type_Requirement__c', String.join(this.typeRequirementsByStatus.get((String) so.get(statusField)), ';'));
        }
    }

}