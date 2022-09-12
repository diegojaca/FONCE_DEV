/**
 * @description       : 
 * @author            : Juan Gabriel Duarte
 * @group             : 
 * @last modified on  : 12-09-2022
 * @last modified by  : diego.jacanamijoy@s4g.es
 * Modifications Log  : New field to query in getFundingRequest
 * Ver   Date         Author                Modification
 * 1.0   05-21-2021   Juan Gabriel Duarte   Initial Version
**/
public without sharing class CreateWebSiteRequest {
    public CreateWebSiteRequest() {

    }

    @AuraEnabled
    public static Contact createContact(Contact cnt) {
        
        try{
            upsert cnt N_mero_de_Documento__c;

        }catch(Exception e){
            System.debug(e);

        }
        return cnt;
    }

    @AuraEnabled
    public static outfunds__Funding_Request__c createFundingRequest(outfunds__Funding_Request__c fundingReq, String recordTypeName) {
        
        try{
            fundingReq.RecordTypeId = Schema.SObjectType.outfunds__Funding_Request__c.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
            upsert fundingReq External_ID__c;
            
        }catch(Exception e){
            System.debug(e);
            
        }
        return fundingReq;
    }

    //se utiliza en fundingRequestManagerLwc
    @AuraEnabled(Cacheable=true)
    public static List<outfunds__Funding_Program__c> getChildFundingPrograms() {
        
        return [SELECT Id, Name, Tipo_de_Programas_de_Becas__c, outfunds__Description__c FROM outfunds__Funding_Program__c WHERE NeedPersonLeadInscription__c = true];
        
    }

    //se utiliza en uniqueFundingRequestFormLwc
    @AuraEnabled(Cacheable=true)
    public static outfunds__Funding_Program__c getFundingProgram(String program) {
        
        return [
                SELECT Id, Nombre_Convocatoria__c, NeedResources__c, NeedRequirementsInRequest__c, Campaign__c, Name
                        , Tipo_de_Programas_de_Becas__c, NeedPersonLeadInscription__c, outfunds__Description__c, IsForPerson__c
                FROM outfunds__Funding_Program__c
                WHERE Nombre_Convocatoria__c = :program
        ].get(0);
        
    }

    @AuraEnabled(Cacheable=true)
    public static List<RecordType> getFundingRequestRecordTypes() {
        
        return [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'outfunds__Funding_Request__c'];
        
    }
    //se utiliza en uniqueFundingRequestFormLwc y en fundingRequestManagerLwc
    @AuraEnabled(Cacheable=true)
    public static List<Type__mdt> getTypesPrograms(Boolean isForUniversityPersons) {
        
        return [SELECT TypeValue__c, RecordTypeName__c, LayoutName__c, ContactLayoutName__c FROM Type__mdt WHERE IsForUniversityPersons__c = :isForUniversityPersons];
        
    }

    @AuraEnabled(Cacheable=true)
    public static List<Field_Definition__mdt> getFields(String type, String sObjectName) {
        
        return [SELECT Id, Entity__r.QualifiedApiName, Field__r.QualifiedApiName, Field__r.Label, Required__c, TypeLayout__r.RecordTypeName__c, Type__c FROM Field_Definition__mdt WHERE TypeLayout__r.TypeValue__c = :type AND Entity__r.QualifiedApiName = :sObjectName];
        
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Boolean> getFields(String layoutName) {
        List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String> {layoutName});
        Map<String, Boolean> fields=new Map<String, Boolean>();
        Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
        for (Metadata.LayoutSection section : layoutMd.layoutSections) {
            for (Metadata.LayoutColumn column : section.layoutColumns) {
                if (column.layoutItems != null) {
                    for (Metadata.LayoutItem item : column.layoutItems) {
                        fields.put(item.field, String.valueOf(item.behavior).equals('Required'));
                    }
                }
            }
        }
        System.debug(fields);
        return fields;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String, Boolean>> getFieldsBySections(String layoutName) {
        List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String> {layoutName});
        Map<String, Map<String, Boolean>> fields=new Map<String, Map<String, Boolean>>();
        Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
        for (Metadata.LayoutSection section : layoutMd.layoutSections) {
            for (Metadata.LayoutColumn column : section.layoutColumns) {
                if (column.layoutItems != null) {
                    for (Metadata.LayoutItem item : column.layoutItems) {
                        if(!fields.containsKey(section.label)){
                            fields.put(section.label, new Map<String, Boolean>());
                        }
                        fields.get(section.label).put(item.field, String.valueOf(item.behavior).equals('Required'));
                    }
                }
            }
        }
        return fields;
    }

    @AuraEnabled(Cacheable=false)
    public static Contact getContactByDni(String dni) {
        
        return [SELECT Id, N_mero_de_Documento__c FROM Contact WHERE N_mero_de_Documento__c = :dni].get(0);
        
    }

    //se utiliza en listProgramsLwc
    @AuraEnabled(cacheable=true)
    public static List<outfunds__Funding_Program__c> getPrograms(String portal) {

        String query = 'SELECT ColorPublicWeb__c, BorderColorPublicWeb__c, Convocatoria__c, Id, Name, Nombre_Convocatoria__c, Minimum_Requirements__c, outfunds__Status__c, IsInProgress__c, IsForUniversity__c, IsForPerson__c '
                      +'FROM outfunds__Funding_Program__c '
                      +'WHERE {0} '
                      +'ORDER BY OrderPublicWeb__c ASC';

        String whereClause = 'outfunds__Top_Level__c = false';
        if(portal.equals('private')){
            whereClause += ' AND visiblePublicWeb__c = true';
        }

        if(portal.equals('person')){
            whereClause += ' AND IsForPerson__c = true';    
        }

        if(portal.equals('university')){
            whereClause += ' AND IsForUniversity__c = true';
        }

        return Database.query(String.format(query, new String[]{whereClause}));

   }

   @AuraEnabled(cacheable=true)
    public static Account getUniversityByContact(String contactId) {
      return [  SELECT Id    
                FROM Account 
                WHERE npe01__One2OneContact__c = :contactId].get(0);
   }

   //se utiliza en UniqueUniversityFormLwc
   @AuraEnabled(cacheable=true)
    public static outfunds__Funding_Program__c getUniversityProgram(String name) {
      return [  SELECT Id, NeedResources__c, NeedRequirementsInRequest__c    
                FROM outfunds__Funding_Program__c 
                WHERE Nombre_Convocatoria__c = :name].get(0);
   }

   @AuraEnabled(Cacheable=true)
    public static RecordType getLeadRecordType(String developerName) {
        
        return [SELECT Id FROM RecordType WHERE SobjectType = 'Lead' AND DeveloperName = :developerName].get(0);
        
    }

    @AuraEnabled(Cacheable=true)
    public static List<LeadType__mdt> getLeadTypes() {
        
        return [SELECT RecordTypeName__c, LayoutName__c FROM LeadType__mdt];
        
    }

    @AuraEnabled(cacheable=true)
    public static List<Section__c> getInnerData(String programId) {
      return [
                SELECT Name, Id, ProgramaBeca__r.IsForUniversity__c, ProgramaBeca__r.NeedPersonLeadInscription__c, ProgramaBeca__r.IsInProgress__c, ProgramaBeca__r.Nombre_Convocatoria__c, ProgramaBeca__r.Minimum_Requirements__c, TitleDisabled__c, RecordType.DeveloperName,
                    (SELECT Id, Description__c, Name, RecordType.DeveloperName, URL__c ,IsImage__c, IsDocument__c, Title__c, IsButton__c, Parent__r.ProgramaBeca__r.Nombre_Convocatoria__c, Type__c, IsVisible__c
                        FROM Sections__r ORDER BY Order__c)  
                FROM Section__c 
                WHERE RecordType.DeveloperName IN ('Principal','ButtonGroup') 
                AND ProgramaBeca__r.Id = :programId
                ORDER BY Order__c ];
   }

    @AuraEnabled
    public static void saveResources(List<Recurso__c> resources){
        try{
            upsert resources;             
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }     
    } 

    @AuraEnabled(Cacheable=true)
    public static outfunds__Funding_Request__c getFundingRequest(String fundingRequestId) {
        
        return [SELECT outfunds__FundingProgram__r.outfunds__Status__c, outfunds__Status__c, outfunds__FundingProgram__r.Nombre_Convocatoria__c, Name, outfunds__FundingProgram__r.NeedResources__c, outfunds__FundingProgram__r.NeedRequirementsInRequest__c, outfunds__Applying_Contact__c FROM outfunds__Funding_Request__c WHERE Id = :fundingRequestId].get(0);
        
    }

    @AuraEnabled(Cacheable=true)
    public static List<ContentDistribution> getContentDistributions(String sectionId) {
        
        return [SELECT ContentDownloadUrl FROM ContentDistribution WHERE ContentVersion.FirstPublishLocationId = :sectionId];
        
    }

    @AuraEnabled(Cacheable=true)
    public static List<outfunds__Funding_Request__c> getFundingRequestsByParents(List<String> parentIds) {
        
        return [SELECT Id, Name, outfunds__Status__c FROM outfunds__Funding_Request__c WHERE Funding_Request__c IN :parentIds];
        
    }

    @AuraEnabled(Cacheable=true)
    public static List<outfunds__Funding_Request__c> getFundingRequestsByOwner(String userId) {
        
        return [SELECT Id, Name, outfunds__Status__c, outfunds__Applying_Organization__c, outfunds__FundingProgram__r.Tipo_de_Programas_de_Becas__c FROM outfunds__Funding_Request__c WHERE OwnerId = :userId AND outfunds__Status__c IN ('Awarded')];
        
    }

    @AuraEnabled(Cacheable=false)
    public static List<Recurso__c> getResourcesByFundingRequestId(String fundingRequestId){
        return [SELECT Funding_Request__c, TipoDeRecurso__c, Cantidad__c, Jornada__c, Presupuesto__c, PorcentajeDelPresupuesto__c, Name FROM Recurso__c WHERE Funding_Request__c = :fundingRequestId];
    } 

    
    @AuraEnabled
    public static void deleteResource(String resourceId){
        try{
            delete new Recurso__c(Id = resourceId);             
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }     
    } 

    @AuraEnabled(Cacheable=true)
    public static List<Portal_Config__mdt> getPortalConfig(){
        return [SELECT Destination__c, Value__c, Config_Type__c FROM Portal_Config__mdt];
    } 

    @AuraEnabled(Cacheable=true)
    public static Portal_Config__mdt getTermsAndConditions(String type, String portalType){
        return [SELECT Value__c FROM Portal_Config__mdt WHERE Type_Program__r.TypeValue__c = :type AND Config_Type__c = 'Terms And Conditions' AND Portal_Type__c = :portalType LIMIT 1];
    } 

    @AuraEnabled(Cacheable=true)
    public static String getDomain(){
        return [SELECT Domain FROM Domain WHERE HttpsOption = 'CommunityAlt'].get(0).Domain;
    } 

    @AuraEnabled
    public static List<outfunds__Funding_Request__c> getActualFundingRequests(String program, String contactId){
        return [SELECT Id, outfunds__Status__c, outfunds__FundingProgram__r.outfunds__Status__c, outfunds__FundingProgram__r.NeedRequirementsInRequest__c FROM outfunds__Funding_Request__c WHERE outfunds__FundingProgram__r.Nombre_Convocatoria__c = :program AND outfunds__Applying_Contact__c = :contactId ];
    } 

    @AuraEnabled
    public static String convertLead(String leadId) {
        List<String> leadFields = new List<String>();
        for(Mapping_Definition__mdt mappingDefinition : [SELECT SourceField__c FROM Mapping_Definition__mdt WHERE TargetObject__c = 'Contact' AND SourceObject__c = 'Lead']){
            if (!mappingDefinition.SourceField__c.equalsIgnoreCase('OwnerId')) {
                leadFields.add(mappingDefinition.SourceField__c);
            }
        }

        String query = 'SELECT OwnerId, {0} FROM Lead WHERE Id =\''+leadId+'\'';
        query = String.format(query, new List<String>{String.join(leadFields, ',')});
        List<Lead> leads = Database.query(query);

        return LeadConversionManager.convertUniqueLead(leads.get(0));
    }
    
    @AuraEnabled(Cacheable=false)
    public static List<pmdm__ProgramEngagement__c> getProgramEngagementsByProgram(String recordId){
        return [SELECT Id, Name, toLabel(pmdm__Stage__c), pmdm__Program__r.Origin_Funding_Request__r.outfunds__FundingProgram__r.Tipo_de_Programas_de_Becas__c FROM pmdm__ProgramEngagement__c WHERE pmdm__Program__c = :recordId]; 
    } 

    @AuraEnabled(Cacheable=false)
    public static List<pmdm__ProgramEngagement__c> getProgramEngagementsByProgramAndContact(String programId, String contactId){
        return [SELECT Id, Name, pmdm__Program__c, pmdm__Contact__c FROM pmdm__ProgramEngagement__c WHERE pmdm__Program__c = :programId AND pmdm__Contact__c = :contactId]; 
    } 

    /**
    * @description Create Campaign member record
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-15-2022 
    * @param leadId Id of Lead
    * @param campaignId Id of campaign
    * @return string 
    **/
    @AuraEnabled
    public static string createMemberCampaign(String leadId, String campaignId){
        try {
            insert new CampaignMember(CampaignId = campaignId, LeadId = leadId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return 'OK';
    }

    @AuraEnabled(Cacheable=true)
    public static pmdm__ProgramEngagement__c getProgramEngagement(String programEngagementId){
        return [SELECT Id, pmdm__Contact__c, (SELECT Id, Name, pmdm__AttendanceStatus__c, pmdm__Service__r.Objective__c FROM pmdm__ServiceDeliveries__r) FROM pmdm__ProgramEngagement__c WHERE Id = :programEngagementId].get(0);
    }

    @AuraEnabled(Cacheable=false)
    public static List<outfunds__Requirement__c> getRequirements(String fundingRequestId, String status, String type, String programId, List<String> serviceDeliveryIds) {
        List<String> types;
        String whereClause;
        if (String.isNotBlank(fundingRequestId)) {
            types = CreateWebSiteRequest.getRequirementTypes(fundingRequestId, type);
            whereClause = 'WHERE outfunds__Funding_Request__c = \'' + fundingRequestId + '\' ';
        } else if (String.isNotBlank(programId)) {
            types = CreateWebSiteRequest.getRequirementTypes(programId, type);
            whereClause = 'WHERE Program__c = \'' + programId + '\' ';
        } else if (serviceDeliveryIds != null && !serviceDeliveryIds.isEmpty() && String.isNotBlank(serviceDeliveryIds.get(0))) {
            types = CreateWebSiteRequest.getRequirementTypes(serviceDeliveryIds.get(0), type);
            whereClause = 'WHERE ServiceDelivery__c IN (\'' + String.join(serviceDeliveryIds, '\',\'') + '\') ';
        } else {
            throw new AuraHandledException('No se ha provisto de un id válido');
        }
        return CreateWebSiteRequest.queryRequirements(status, types, whereClause);
    }

    private static List<String> getRequirementTypes(String recordId, String type) {
        List<String> types = new List<String>();
        if (String.isBlank(type) && String.isNotBlank(recordId)) {
            Id recordIdProvided = Id.valueOf(recordId);
            String typesQueried;
            if (recordIdProvided.getSobjectType() == outfunds__Funding_Request__c.getSObjectType()) {
                typesQueried = [
                        SELECT Type_Requirement__c
                        FROM outfunds__Funding_Request__c
                        WHERE Id = :recordIdProvided
                        LIMIT 1
                ].Type_Requirement__c;
            } else if (recordIdProvided.getSobjectType() == pmdm__Program__c.getSObjectType()) {
                typesQueried = [
                        SELECT Type_Requirement__c
                        FROM pmdm__Program__c
                        WHERE Id = :recordIdProvided
                        LIMIT 1
                ].Type_Requirement__c;
            } else if (recordIdProvided.getSobjectType() == pmdm__ServiceDelivery__c.getSObjectType()) {
                typesQueried = [
                        SELECT pmdm__Program__r.Type_Requirement__c
                        FROM pmdm__ProgramEngagement__c
                        WHERE Id IN (
                                SELECT pmdm__ProgramEngagement__c
                                FROM pmdm__ServiceDelivery__c
                                WHERE Id = :recordIdProvided
                        )
                        LIMIT 1
                ].pmdm__Program__r.Type_Requirement__c;
            }
            if (String.isNotBlank(typesQueried)) {
                types.addAll(typesQueried.split(';'));
            }
        } else if (String.isNotBlank(type)) {
            types.add(type);
        }
        return types;
    }

    private static List<outfunds__Requirement__c> queryRequirements(String status, List<String> types, String whereClause) {
        String query = 'SELECT Id, Name, outfunds__Type__c, toLabel(outfunds__Status__c), IsRequired__c, ReasonForRejection__c '
                + 'FROM outfunds__Requirement__c ';
        query += whereClause;

        if (String.isNotBlank(status)) {
            List<String> statuses = status.split(',');
            String statusCondition = ' AND outfunds__Status__c IN (\'' + String.join(statuses, '\',\'') + '\') ';
            query += statusCondition;
        }
        if (!types.isEmpty()) {
            String typeCondition = ' AND outfunds__Type__c IN ' + '(\'' + String.join(types, '\',\'') + '\')';
            query += typeCondition;
        }
        query += ' ORDER BY IsRequired__c DESC';
        System.debug('query: ' + query);
        return Database.query(query);
    }

    /**
    * @description 
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 07-05-2022 
    * @return Account[] 
    **/
    @AuraEnabled(Cacheable = true)
    public static Account[] getUniversities(){
        Account[] universities;
        try {
            universities = [SELECT Name FROM Account WHERE IsPartner = true ORDER BY NAME];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return universities;
    }

    /**
    * @description 
    * @author César Parra -> cesar.parra@s4g.es | 07-14-2022 
    * @return Boolean 
    **/
    @AuraEnabled(Cacheable = false)
    public static Boolean fireAssignmentRule(String leadId){    

        Lead lead = [SELECT Id, BecaDeInteres__c, ComunidadAutonoma__c, RecordTypeId FROM Lead WHERE Id = :leadId];
        
        AssignmentRule assignmentRule = new AssignmentRule();
        assignmentRule = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Lead' AND Active = TRUE AND Name = :CONSTANTS.ASSIGNMENT_RULE_NAME].get(0);

        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId = assignmentRule.Id;

        try{
            Database.update(lead, dmlOpts);
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
        return true;
    }

    @AuraEnabled(Cacheable=true)
    public static pmdm__Program__c getProgramType(String recordId){
        return [SELECT Id, Origin_Funding_Request__r.outfunds__FundingProgram__r.Tipo_de_Programas_de_Becas__c FROM pmdm__Program__c WHERE Id = :recordId].get(0); 
    } 

}