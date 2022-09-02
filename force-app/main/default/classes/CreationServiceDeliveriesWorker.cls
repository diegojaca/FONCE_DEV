/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 07-04-2022
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
**/
global with sharing class CreationServiceDeliveriesWorker extends AbstractWorker {

    private Map<String, List<pmdm__Service__c>> servicesByProgramId = new Map<String, List<pmdm__Service__c>>();
    private List<pmdm__ServiceDelivery__c> serviceDeliveries = new List<pmdm__ServiceDelivery__c>();
    private Map<String, String> objectiveIdByServiceId = new Map<String, String>();
    private Map<String, List<outfunds__Requirement__c>> requirementsByObjectiveId = new Map<String, List<outfunds__Requirement__c>>();
    private List<outfunds__Requirement__c> requirements = new List<outfunds__Requirement__c>();
    private Set<String> fundingRequestIds = new Set<String>();
    private Map<String,String> disbursementByPaymentStg = new Map<String,String>();

    public CreationServiceDeliveriesWorker() {
        super(String.valueOf(CreationServiceDeliveriesWorker.class));
    }

    public override void bulkAfterInsert(List<SObject> newRecords){
        Set<String> programIds = new Set<String>();
        for(pmdm__ProgramEngagement__c programEngagement : (List<pmdm__ProgramEngagement__c>) newRecords){
            if(String.IsNotBlank(programEngagement.pmdm__Program__c)){
                programIds.add(programEngagement.pmdm__Program__c);
            }
        }
        this.getServices(programIds);
        this.getRequirements(objectiveIdByServiceId.values());
        this.getDisbursements();
	}

    public override void afterInsert(SObject so){
        this.cloneServices((pmdm__ProgramEngagement__c) so);
    }

    public override void andFinallyAfter(){

        Database.SaveResult[] insertServiceDeliveries = Database.insert(this.serviceDeliveries, false);

        for(Integer i = 0; i < insertServiceDeliveries.size(); i++){
            if(!insertServiceDeliveries[i].isSuccess()){
                this.serviceDeliveries[i].addError('Error al crear el requerimiento.');
            }else{
                this.cloneRequirements(this.serviceDeliveries[i]);
            }
        }  
        Database.SaveResult[] insertRequirements = Database.insert(this.requirements, false);
    }
    /**
    * @description search a services´s programs
    * @param programIds
    */
    private void getServices(Set<String> programIds){
        for(pmdm__Service__c service : [SELECT Id, Name, pmdm__Program__c, Objective__r.Objective__c, Objective__r.Funding_Request__c FROM pmdm__Service__c WHERE pmdm__Program__c IN :programIds]){
            if(!this.servicesByProgramId.containsKey(service.pmdm__Program__c)){
                this.servicesByProgramId.put(service.pmdm__Program__c, new List<pmdm__Service__c>());
            }
            this.servicesByProgramId.get(service.pmdm__Program__c).add(service);

            if(!this.objectiveIdByServiceId.containsKey(service.Id)){
                this.objectiveIdByServiceId.put(service.Id, service.Objective__r.Objective__c);
            }

            this.fundingRequestIds.add(service.Objective__r.Funding_Request__c);
        }
    }
    /**
    * @description search a requirement´s objective
    * @param objectiveIds
    */
    private void getRequirements(List<String> objectiveIds){
        //TODO si alguno de los objetivos no tiene padre (es null) se trae todos los requisitos que no tengan padre y hace reventar la creación de requisitos porque se ha traido muchos
        for(outfunds__Requirement__c requirement : [SELECT Id, Funding_Program__c, outfunds__Type__c, PaymentSetting__c, Name, IsRequired__c, RequirementCategory__c, Objective__c, RecordTypeId FROM outfunds__Requirement__c WHERE Objective__c IN :objectiveIds]){
            if(!this.requirementsByObjectiveId.containsKey(requirement.Objective__c)){
                this.requirementsByObjectiveId.put(requirement.Objective__c, new List<outfunds__Requirement__c>());
            }
            this.requirementsByObjectiveId.get(requirement.Objective__c).add(requirement);
        }
    }

    /**
    * @description This method get requirements and build map of disbursements
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 07-04-2022 
    **/
    private void getDisbursements(){
        for(outfunds__Disbursement__c disbursement: [SELECT 
                                                        PaymentSetting__c 
                                                    FROM outfunds__Disbursement__c 
                                                    WHERE outfunds__Funding_Request__c IN: this.fundingRequestIds
                                                    AND PaymentSetting__c <> NULL
                                                    ])
        {
            this.disbursementByPaymentStg.put(disbursement.PaymentSetting__c, disbursement.Id);
        }
    }

    /**
    * @description clone a list of requirements
    * @param fundingRequest modified funding request record
    */
    private void cloneServices(pmdm__ProgramEngagement__c programEngagement){
        if(this.servicesByProgramId.containsKey(programEngagement.pmdm__Program__c)){
            for(pmdm__Service__c service : this.servicesByProgramId.get(programEngagement.pmdm__Program__c)){
                pmdm__ServiceDelivery__c serviceDelivery = new pmdm__ServiceDelivery__c();
                serviceDelivery.Name = service.Name;
                serviceDelivery.pmdm__Contact__c = programEngagement.pmdm__Contact__c;
                serviceDelivery.pmdm__Service__c = service.Id;
                serviceDelivery.pmdm__ProgramEngagement__c = programEngagement.Id;
                this.serviceDeliveries.add(serviceDelivery);
            }
        }
    }
    /**
    * @description clone a list of requirements
    * @param fundingRequest modified funding request record
    */
    private void cloneRequirements(pmdm__ServiceDelivery__c serviceDelivery){
        if(this.objectiveIdByServiceId.containsKey(serviceDelivery.pmdm__Service__c) && this.requirementsByObjectiveId.containsKey(this.objectiveIdByServiceId.get(serviceDelivery.pmdm__Service__c))){
            for(outfunds__Requirement__c requirement : this.requirementsByObjectiveId.get(this.objectiveIdByServiceId.get(serviceDelivery.pmdm__Service__c))){
                outfunds__Requirement__c newRequirement = requirement.clone(false, true, false, false);
                newRequirement.recordTypeId = CONSTANTS.REQUIREMENT_RT_REQUIRE_DOCUMENT;
                newRequirement.ServiceDelivery__c = serviceDelivery.Id;
                newRequirement.Funding_Program__c = null;
                newRequirement.Objective__c = null;
                newRequirement.PaymentSetting__c = null;
                newRequirement.outfunds__Disbursement__c = this.disbursementByPaymentStg.get(requirement.PaymentSetting__c);
                this.requirements.add(newRequirement);
            }
        }
    }
}