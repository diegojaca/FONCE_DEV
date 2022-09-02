/**
 * @description       : This class execute clone proccess of contacts, it´s recommended to use a maximum list of 10 records
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 06-10-2022
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
**/
public with sharing class MergeContactsHelper {

    private List<Contact> masterContacts;
    private List<Contact> duplicateContacts;
    private List<String> allContactFields;
    private Map<String,List<Contact>> duplicatesByDNI = new Map<String,List<Contact>>();
    private Map<String,Contact> mastersByDNI = new Map<String,Contact>();

    /**
    * @description Contructor with master contacts
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-09-2022 
    * @param masterContacts List of master contacts
    **/
    public MergeContactsHelper(List<Contact> masterContacts) {
        this.masterContacts = masterContacts;
        this.allContactFields = S4GUtils.getAllFieldsInSObject(SObjectType.Contact.getName(), true, true, true);
    }

    /**
    * @description Main method, to execute merge proccess
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-09-2022 
    **/
    public void execute(){

        try {
            this.searchDuplicatesByDNI();
            this.mapFieldsToMaster();
            this.checkMergeContacts();    
        } catch (Exception e) {
            throw new MergeContactException( Label.MERGE_CONTACT_EXCEPTION_MESSAGE, e);
        }
        
    }

    /**
    * @description Search duplicate contacts by document number
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-09-2022 
    **/
    public void searchDuplicatesByDNI(){

        Set<String> documentNumbers = new Set<String>();
        Set<Id> masterIds = new Set<Id>();

        //Querys to master and duplicate contacts
        String queryMasters = 'SELECT {0} FROM Contact WHERE Id IN: masterIds';
        String queryDuplicates = 'SELECT {0} FROM Contact WHERE N_mero_de_Documento__c IN: documentNumbers AND Id NOT IN: masterIds ORDER BY CreatedDate DESC';

        for(Contact masterContact: masterContacts){

            if(String.isNotBlank(masterContact.N_mero_de_Documento__c)){
                documentNumbers.add(masterContact.N_mero_de_Documento__c);
                masterIds.add(masterContact.Id);
            }
        }

        //If there aren´t contatcs to query, exit
        if(masterIds.isEmpty()){
            return;
        }

        //All Contact fields to querys
        List<String> params = new List<String>{String.join(allContactFields, ',')};

        //Build map of master contacts by document number
        this.buildMasterContactMap(Database.query(String.format(queryMasters, params)));
        
        //Build map of duplicate contacts by document number
        this.buildDuplicateContactMap(Database.query(String.format(queryDuplicates, params)));
    }

    /**
    * @description Build map of master contacts
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-09-2022 
    * @param contacts List of master contacts
    **/
    private void buildMasterContactMap(List<Contact> contacts){

        for(Contact contact: contacts){
            //Build map
            mastersByDNI.put(contact.N_mero_de_Documento__c, contact);
        }
    }

    /**
    * @description Build map of duplicate contacts
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-09-2022 
    * @param contacts List of duplicate contacts
    **/
    private void buildDuplicateContactMap(List<Contact> contacts){

        for(Contact contact: contacts){
            //Build map
            if(!duplicatesByDNI.containsKey(contact.N_mero_de_Documento__c)){
                duplicatesByDNI.put(contact.N_mero_de_Documento__c, new List<Contact>());
            }
            duplicatesByDNI.get(contact.N_mero_de_Documento__c).add(contact);
        }
    }

    /**
    * @description Copy fields from duplicate contacts if it´s null in master
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-09-2022 
    **/
    public void mapFieldsToMaster(){

        for(String docNumKey: mastersByDNI.keySet()){
            if(duplicatesByDNI.containsKey(docNumKey)){
                this.checkDuplicateContactList(mastersByDNI.get(docNumKey), duplicatesByDNI.get(docNumKey));
            }
        }
    }

    /**
    * @description Check duplicates by master contact
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-09-2022 
    * @param master master contact
    * @param duplicates list of duplicates
    **/
    public void checkDuplicateContactList(Contact master, List<Contact> duplicates){
        for (Contact duplicate : duplicates) {
            for (String fieldName : allContactFields){
                if(this.checkEmptyFields(master, fieldName) && !this.checkEmptyFields(duplicate, fieldName)){
                    master.put(fieldName, duplicate.get(fieldName));
                }
            }
        }
    }

    /**
    * @description Check empty fields by contact record
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-09-2022 
    * @param contact contact record
    * @param fieldName name field of contact
    * @return boolean 
    **/
    public boolean checkEmptyFields(Contact contact, String fieldName){
        return contact.get(fieldName) == null || contact.get(fieldName) == '' || contact.get(fieldName) == false;
    }

    /**
    * @description Check contacts to merge
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-09-2022 
    **/
    public void checkMergeContacts(){

        WorkersManager.avoidAllWorkersExecution(true);

        for(String docNumKey: mastersByDNI.keySet()){

            if(duplicatesByDNI.containsKey(docNumKey)){

                Integer duplicatedNumber = duplicatesByDNI.get(docNumKey).size();
                if(duplicatedNumber > 2){
                    this.checkMassDuplicates(mastersByDNI.get(docNumKey), duplicatesByDNI.get(docNumKey));
                }else{
                    this.mergeContacts(mastersByDNI.get(docNumKey), duplicatesByDNI.get(docNumKey));
                }
            }
        }

        WorkersManager.avoidAllWorkersExecution(false);
    }

    /**
    * @description procces merge with mass duplicates
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-09-2022 
    * @param master master contact
    * @param duplicates list of duplicates
    **/
    public void checkMassDuplicates(Contact master, List<Contact> duplicates){

        //Loop duplicate contats, call ,merge metod each two elements
        for(Integer i = 0; i <= duplicates.size() -1; i+=2){
            //if the number of elements is odd only send the last one
            if(i == duplicates.size() -1){
                this.mergeContacts(master, new List<Contact>{duplicates[i]});
            }else {
                this.mergeContacts(master, new List<Contact>{duplicates[i], duplicates[i + 1]});
            }
        }
    }

    /**
    * @description Execute merge of contacts
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-09-2022 
    * @param master master contact
    * @param duplicates list of duplicates
    **/
    public void mergeContacts(Contact master, List<Contact> duplicates){

        merge master duplicates;
    }

    //Inner class to custom exception
    public class MergeContactException extends Exception{}
}