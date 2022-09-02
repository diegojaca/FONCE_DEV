/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 06-23-2022
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
**/
global without sharing class MaxRequestsForParentWorker extends AbstractWorker {
    public class MaxRequestsForUniversityException extends Exception {}
    private Map<String, Integer> requestCountByInternalId = new Map<String, Integer>();
    private static String REQUEST_ORGANIZATION_FIELD = outfunds__Funding_Request__c.outfunds__Applying_Organization__c.getDescribe().getName();
    private static String REQUEST_CONTACT_FIELD = outfunds__Funding_Request__c.outfunds__Applying_Contact__c.getDescribe().getName();
    
    /**
     * @description Set worker Id
     * @param workerId Set child worker Id
     */
    global MaxRequestsForParentWorker() {
        super(String.valueOf(MaxRequestsForParentWorker.class));
    }

    public override void bulkBeforeInsert(List<SObject> newRecords){
        this.prepareData(newRecords);
    }

    public override void beforeInsert(SObject so) {
        outfunds__Funding_Request__c newFundingRequest = (outfunds__Funding_Request__c) so;
        this.checkRequestByParent(newFundingRequest);
    }

    /**
    * @description Init method to prepare required data to proccess
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-23-2022 
    * @param newRecords 
    **/
    public void prepareData(List<SObject> newRecords){

        Set<String> organizationIds = new Set<String>();
        Set<String> contactIds = new Set<String>();
        Set<String> programIds = new Set<String>();
        
        for(outfunds__Funding_Request__c newFundingRequest : (List<outfunds__Funding_Request__c>) newRecords){

            //Check requests by university and buuild map of requests by university
            if(this.isRequestByUniversity(newFundingRequest)){
                organizationIds.add(newFundingRequest.outfunds__Applying_Organization__c);
                programIds.add(newFundingRequest.outfunds__FundingProgram__c);
                this.addRequestToMap(newFundingRequest, MaxRequestsForParentWorker.REQUEST_ORGANIZATION_FIELD);
            }

            //Check requests by contact and buuild map of requests by contact
            if(this.isRequestByContact(newFundingRequest)){
                contactIds.add(newFundingRequest.outfunds__Applying_Contact__c);
                programIds.add(newFundingRequest.outfunds__FundingProgram__c);
                this.addRequestToMap(newFundingRequest, MaxRequestsForParentWorker.REQUEST_CONTACT_FIELD);
            }
        }

        //List of Scholarships Program Types to avoid validation of requests by contact
        List<String> invalidScholarshipsProgramTypes = new List<String>{CONSTANTS.FOR_DIGITAL_TALENT};

        //Query current requests by programs and (university or contact)
        for(outfunds__Funding_Request__c request : [SELECT Id, outfunds__FundingProgram__c, outfunds__Applying_Organization__c, outfunds__Applying_Contact__c,
                                                            outfunds__FundingProgram__r.IsForUniversity__c, outfunds__FundingProgram__r.Tipo_de_Programas_de_Becas__c
                                                        FROM outfunds__Funding_Request__c 
                                                        WHERE outfunds__FundingProgram__c IN :programIds
                                                        AND (
                                                            (outfunds__Applying_Organization__c IN :organizationIds AND outfunds__FundingProgram__r.IsForUniversity__c = true)
                                                            OR 
                                                            (outfunds__Applying_Contact__c IN: contactIds AND outfunds__FundingProgram__r.Tipo_de_Programas_de_Becas__c NOT IN: invalidScholarshipsProgramTypes)
                                                            )]){
            this.checkCurentRequests(request);
        }
    }

    /**
    * @description Check data of current requests
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-23-2022 
    * @param request 
    **/
    public void checkCurentRequests(outfunds__Funding_Request__c request){

        //Check if current request is by university or contact
        if (this.isRequestByUniversity(request) && request.outfunds__FundingProgram__r.IsForUniversity__c) {
            this.addRequestToMap(request, MaxRequestsForParentWorker.REQUEST_ORGANIZATION_FIELD);
        } else if(this.isRequestByContact(request) && request.outfunds__FundingProgram__r.Tipo_de_Programas_de_Becas__c <> CONSTANTS.FOR_DIGITAL_TALENT) {
            this.addRequestToMap(request, MaxRequestsForParentWorker.REQUEST_CONTACT_FIELD);
        }
    }

    /**
    * @description Check data of new requests
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-23-2022 
    * @param request 
    **/
    public void checkRequestByParent(outfunds__Funding_Request__c request){

        //Check if new request is by university or contact
        if (this.isRequestByUniversity(request)) {
            this.validateMaxRequest(request, MaxRequestsForParentWorker.REQUEST_ORGANIZATION_FIELD);
        } else if(this.isRequestByContact(request)) {
            this.validateMaxRequest(request, MaxRequestsForParentWorker.REQUEST_CONTACT_FIELD);
        }
    }

    /**
    * @description Validate max requests by parent
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-23-2022 
    * @param newFundingRequest 
    * @param keyParentField 
    **/
    public void validateMaxRequest(outfunds__Funding_Request__c newFundingRequest, String keyParentField){

        //Build key
        String internalId = this.generateInternalId(newFundingRequest, keyParentField);

        //Check if exceeds the limit
        if(this.requestCountByInternalId.containsKey(internalId) && this.requestCountByInternalId.get(internalId) > 1){
            newFundingRequest.addError('Ya hay otra solicitud para este programa.');
        }
    }

    /**
    * @description Build map of request by program + parent (University or Contact)
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-23-2022 
    * @param newFundingRequest 
    * @param keyParentField 
    **/
    private void addRequestToMap(outfunds__Funding_Request__c newFundingRequest, String keyParentField){

        //Build key
        String internalId = this.generateInternalId(newFundingRequest, keyParentField);

        //Build map
        if(this.requestCountByInternalId.containsKey(internalId)){
            Integer count = this.requestCountByInternalId.get(internalId) + 1;
            this.requestCountByInternalId.put(internalId, count);
        }else{
            this.requestCountByInternalId.put(internalId, 1);
        }
    }

    /**
    * @description Build key by program + parent (university or contact)
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-23-2022 
    * @param newFundingRequest 
    * @param keyParentField 
    * @return String 
    **/
    private String generateInternalId(outfunds__Funding_Request__c newFundingRequest, String keyParentField){
        return newFundingRequest.outfunds__FundingProgram__c+'-'+newFundingRequest.get(keyParentField);
    }

    /**
    * @description Check valida request by university
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-23-2022 
    * @param request 
    * @return Boolean 
    **/
    public Boolean isRequestByUniversity(outfunds__Funding_Request__c request){
        return String.isNotBlank(request.outfunds__Applying_Organization__c) && String.isNotBlank(request.outfunds__FundingProgram__c);
    }

    /**
    * @description Check valida request by contact
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-23-2022 
    * @param request 
    * @return Boolean 
    **/
    public Boolean isRequestByContact(outfunds__Funding_Request__c request){
        return String.isNotBlank(request.outfunds__Applying_Contact__c) && String.isNotBlank(request.outfunds__FundingProgram__c);
    }

}