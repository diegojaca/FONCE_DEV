/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 05-04-2022
 * @last modified by  : cesar.parra@s4g.es
**/
global with sharing class ClosedRequestsBatch implements Database.Batchable<sObject> {

    private static final Integer BATCH_SIZE = 200;
    private String completeStatusList = '(\'' + String.join(new List<String>{'In progress'}, '\',\'') + '\')';

    private String query ='SELECT Id, outfunds__Status__c'    
                            +' FROM outfunds__Funding_Request__c' 
                            +' WHERE {0}';
    
    global Database.Querylocator start(Database.BatchableContext bc){
        String whereClause = 'outfunds__FundingProgram__r.outfunds__Status__c IN (\'Completed\')' 
                            // +' AND outfunds__FundingProgram__r.outfunds__End_Date__c = TODAY'
                            +' AND outfunds__Status__c IN ' + this.completeStatusList ;
                            
        return Database.getQuerylocator(String.format(this.query, new List<String> {whereClause}));
    } 
    
    global void execute(Database.BatchableContext bc, List<sObject> scope){
        for(outfunds__Funding_Request__c request : (List<outfunds__Funding_Request__c>) scope){
            request.outfunds__Status__c = 'Incompleta';  
        } 
        update scope;
    }
    
    global void finish(Database.BatchableContext bc){
    }

    public static void runMe(Integer size){
        Database.executebatch(new ClosedRequestsBatch(), size);
    }

    public static void runMe(){
        ClosedRequestsBatch.runMe(ClosedRequestsBatch.BATCH_SIZE);
    }

}