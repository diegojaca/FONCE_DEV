/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 05-26-2022
 * @last modified by  : cesar.parra@s4g.es
**/
global with sharing class EndAllegationsProgramBatch implements Schedulable , Database.Batchable<sObject> {

    private static final Integer BATCH_SIZE = 200;

    private String query ='SELECT Id, outfunds__Status__c'    
                            +' FROM outfunds__Funding_Request__c' 
                            +' WHERE {0}';
    
    global Database.Querylocator start(Database.BatchableContext bc){
        String whereClause = 'outfunds__Status__c =\'En Proceso de Alegaciones/Subsanaciones\'' 
                            +' AND outfunds__FundingProgram__r.AllegationsEndDate__c = YESTERDAY';
                            
        return Database.getQuerylocator(String.format(this.query, new List<String> {whereClause}));
    } 
    
    global void execute(Database.BatchableContext bc, List<sObject> scope){
        for(outfunds__Funding_Request__c request : (List<outfunds__Funding_Request__c>) scope){
            request.outfunds__Status__c = 'Resolución Final';  
        } 
        update scope;
    }
    
    global void finish(Database.BatchableContext bc){
    }

    public static void runMe(Integer size){
        Database.executebatch(new EndAllegationsProgramBatch(), size);
    }

    public static void runMe(){
        EndAllegationsProgramBatch.runMe(EndAllegationsProgramBatch.BATCH_SIZE);
    }

    global void execute(SchedulableContext ctx){
        EndAllegationsProgramBatch.runMe();
    }
}