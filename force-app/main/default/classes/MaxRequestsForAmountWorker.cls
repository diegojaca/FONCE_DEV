/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 09-02-2022
 * @last modified by  : diego.jacanamijoy@s4g.es
**/
global without sharing class MaxRequestsForAmountWorker extends AbstractWorker {

    private Set<String> programIds = new Set<String>();
    private Set<String> contactIds = new Set<String>();
    private Set<String> requestIds = new Set<String>();//This ids, are excludes in the amount query
    private Map<String, Decimal> totalRequestAmountByProgram = new Map<String, Decimal>();
    
    //Constructor
    global MaxRequestsForAmountWorker() {
        super(String.valueOf(MaxRequestsForAmountWorker.class));
    }

    //Overide bulkBeforeInsert
    public override void bulkBeforeInsert(List<SObject> newRecords){
       this.prepareData(newRecords);
    }

    //Override bulkBeforeUpdate
    public override void bulkBeforeUpdate(List<SObject> oldRecords, List<SObject> newRecords){
        this.checkChangeAmountvalue(newRecords);
    }

    //Override beforeInsert
    public override void beforeInsert(SObject so) {
        this.checkNewTotalAmountByProgram((outfunds__Funding_Request__c)so);
    }

    //Override beforeUpdate
    public override void beforeUpdate(SObject oldSo, SObject so){
        if(this.checkChangeAmountvalue((outfunds__Funding_Request__c)so, (outfunds__Funding_Request__c)oldSo)){
            this.checkNewTotalAmountByProgram((outfunds__Funding_Request__c)so);
        }
    }

    /**
    * @description validate if it´s changed amount field and query current requests
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-24-2022 
    * @param newRecords 
    **/
    private void checkChangeAmountvalue(List<SObject> newRecords){
        for(outfunds__Funding_Request__c request: (List<outfunds__Funding_Request__c>) newRecords){
            if(this.checkChangeAmountvalue(request, (outfunds__Funding_Request__c)super.oldRecordsMap.get(request.Id))
                && String.isNotBlank(request.outfunds__FundingProgram__c) 
                && String.isNotBlank(request.outfunds__Applying_Contact__c)){

                this.programIds.add(request.outfunds__FundingProgram__c);
                this.contactIds.add(request.outfunds__Applying_Contact__c);
                this.requestIds.add(request.Id);
            }
        }

        if(this.programIds.isEmpty()) return;
        this.getCurrentRequestByprogram();
    }

    /**
    * @description validate if it´s changed amount field
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-24-2022 
    * @param newRequest 
    * @param oldRequest 
    * @return boolean 
    **/
    private boolean checkChangeAmountvalue(outfunds__Funding_Request__c newRequest, outfunds__Funding_Request__c oldRequest){
        return String.isNotBlank(newRequest.outfunds__FundingProgram__c) && S4GUtils.isChanged(newRequest, oldRequest, 'outfunds__Awarded_Amount__c');
    }

    /**
    * @description main method to prepare data to proccess
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-24-2022 
    * @param newRecords 
    **/
    private void prepareData(List<SObject> newRecords){

        for(outfunds__Funding_Request__c request: (List<outfunds__Funding_Request__c>) newRecords){
            if(String.isNotBlank(request.outfunds__FundingProgram__c) && String.isNotBlank(request.outfunds__Applying_Contact__c)){

                this.programIds.add(request.outfunds__FundingProgram__c);
                this.contactIds.add(request.outfunds__Applying_Contact__c);
                this.requestIds.add(request.Id);
            }
        }

        if(this.programIds.isEmpty()) return;
        this.getCurrentRequestByprogram();
    }

    /**
    * @description Query current requests by program
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-24-2022 
    * @param programIds 
    **/
    private void getCurrentRequestByprogram(){

        if(this.programIds.isEmpty())return;

        //Build map from request query
        for(AggregateResult ar: [SELECT Sum(outfunds__Awarded_Amount__c)totalAmount, outfunds__FundingProgram__c, outfunds__Applying_Contact__c 
                                FROM outfunds__Funding_Request__c 
                                WHERE outfunds__FundingProgram__c IN: this.programIds
                                AND outfunds__Applying_Contact__c IN: this.contactIds
                                AND Id NOT IN: this.requestIds 
                                AND outfunds__FundingProgram__r.Tipo_de_Programas_de_Becas__c =: CONSTANTS.FOR_DIGITAL_TALENT
                                GROUP BY outfunds__FundingProgram__c, outfunds__Applying_Contact__c]){
            
            Decimal totalAountAux = (Decimal)ar.get('totalAmount') <> null ? (Decimal)ar.get('totalAmount') : 0;
            String keyAux = (String)ar.get('outfunds__FundingProgram__c') + '-' + (String)ar.get('outfunds__Applying_Contact__c');
            //Build map, total amount by porgram + contact
            this.totalRequestAmountByProgram.put(keyAux, totalAountAux);
        }
    }

    /**
    * @description Validate total request amount with new record
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-24-2022 
    * @param request 
    **/
    private void checkNewTotalAmountByProgram(outfunds__Funding_Request__c request){

        String auxKey = request.outfunds__FundingProgram__c + '-' + request.outfunds__Applying_Contact__c;
        Decimal auxAmount = request.outfunds__Awarded_Amount__c <> null ? request.outfunds__Awarded_Amount__c.setscale(2) : 0;

        if(this.totalRequestAmountByProgram.containsKey(auxKey) && (this.totalRequestAmountByProgram.get(auxKey) + auxAmount) >= CONSTANTS.MAX_TOTAL_REQUEST_AMOUNT_BY_PROGRAM){
            request.addError(String.format(Label.MAX_TOTAL_REQUEST_AMOUNT_BY_PROGRAM_MESSAGE, new List<Decimal>{CONSTANTS.MAX_TOTAL_REQUEST_AMOUNT_BY_PROGRAM}));
        }
    }
}