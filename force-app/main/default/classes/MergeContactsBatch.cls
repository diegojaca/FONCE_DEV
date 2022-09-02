/**
 * @description       : Batch to calll merge contact proccess
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 06-14-2022
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
**/
public with sharing class MergeContactsBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

    private String query;
    private static final Integer BATCH_SIZE = 10;

    /**
    * @description Query master contact list
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-10-2022 
    **/
    public MergeContactsBatch() {
        this.query = 'SELECT N_mero_de_Documento__c FROM Contact WHERE Consultar_duplicados__c = true';
    }

    /**
    * @description 
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-10-2022 
    * @param bC Batchable Context
    * @return Database.QueryLocator 
    **/
    public Database.QueryLocator start(Database.BatchableContext bC){
        return Database.getQueryLocator(query);
    }

    /**
    * @description 
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-10-2022 
    * @param bC Batchable Context
    * @param scope Contact list to proccess
    **/
    public void execute(Database.BatchableContext bC, List<sObject> scope){

        //Send master contacts to search duplicates and merge
        MergeContactsHelper mergeContacts = new MergeContactsHelper((List<Contact>) scope);
        mergeContacts.execute();

        //Update contacts with Consultar_duplicados__c = false
        List<Contact> contactsToUpdate = (List<Contact>)scope;
        for(Contact contact: contactsToUpdate){
            contact.Consultar_duplicados__c = false;
        }

        WorkersManager.avoidAllWorkersExecution(true);
        update contactsToUpdate;
        WorkersManager.avoidAllWorkersExecution(false);
    }
    
    /**
    * @description Execute schedule batch
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-10-2022 
    * @param sc Schedulable Context
    **/
    public void execute(SchedulableContext sc) {
        MergeContactsBatch.runMe();
    }

    /**
    * @description Execute batch with expecific size
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-10-2022 
    * @param size batch size
    **/
    public static void runMe(Integer size){
        Database.executebatch(new MergeContactsBatch(), size);
    }

    /**
    * @description Execute batch with predefined size
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-10-2022 
    **/
    public static void runMe(){
        MergeContactsBatch.runMe(MergeContactsBatch.BATCH_SIZE);
    }

    public void finish(Database.BatchableContext bC){}
}