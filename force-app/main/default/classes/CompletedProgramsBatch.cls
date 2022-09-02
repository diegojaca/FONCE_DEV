/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 05-26-2022
 * @last modified by  : cesar.parra@s4g.es
**/
global class CompletedProgramsBatch implements Schedulable , Database.Batchable<sObject> {

    private static final Integer BATCH_SIZE = 200;

    private String query ='SELECT Id'    
                            +' FROM outfunds__Funding_Program__c' 
                            +' WHERE outfunds__End_Date__c = YESTERDAY AND outfunds__Status__c != \'Aborted\'';
    
    global Database.Querylocator start(Database.BatchableContext bc){
        return Database.getQuerylocator(query);
    } 
    
    global void execute(Database.BatchableContext bc, List<sObject> scope){
        for(outfunds__Funding_Program__c program : (List<outfunds__Funding_Program__c>) scope){
            program.outfunds__Status__c = 'Completed';  
        } 
        update scope;
    }
    
    global void finish(Database.BatchableContext bc){
        ClosedRequestsBatch.runMe();
    }

    public static void runMe(Integer size){
        Database.executebatch(new CompletedProgramsBatch(), size);
    }

    public static void runMe(){
        CompletedProgramsBatch.runMe(CompletedProgramsBatch.BATCH_SIZE);
    }

    global void execute(SchedulableContext ctx){
        CompletedProgramsBatch.runMe();
    }
}