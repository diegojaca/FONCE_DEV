/**
 * @description       : 
 * @author            : cesar.parra@s4g.es
 * @group             : 
 * @last modified on  : 06-10-2022
 * @last modified by  : cesar.parra@s4g.es
**/
public without sharing class LeadConversionManager {

    private static LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
    private static Map<String, Database.LeadConvert> leadConvertByLeadId = new Map<String, Database.LeadConvert>();
    private static Map<String, String> contactIdByLeadId = new Map<String, String>();

    public LeadConversionManager() {
    }

    public static void processMapping(List<Lead> leads){
        List<Lead> leadsToUpdate = new List<Lead>();
        for(Lead lead : leads){
            if(!LeadConversionManager.leadConvertByLeadId.containsKey(lead.Id)){
                if (!String.valueOf(lead.OwnerId).startsWith('005')) {
                    leadsToUpdate.add(new Lead(Id = lead.Id, OwnerId = UserInfo.getUserId()));
                }
                LeadConversionManager.leadConvertByLeadId.put(lead.Id, LeadConversionManager.createLeadConvert(lead.Id));
            }
        }
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
        LeadConversionManager.processMappingContact(leads);
        List<Database.LeadConvertResult> lcrs = LeadConversionManager.convertLeads();

        for(Database.LeadConvertResult lcr : lcrs){
            LeadConversionManager.contactIdByLeadId.put(lcr.getLeadId(), lcr.getContactId());
        }
    }
    
    public static void processMappingContact(List<Lead> leads){
        List<String> dnis = new List<String>();
        List<Contact> contacts = new List<Contact>();
        List<Mapping_Definition__mdt> leadMappingContactMetadata = LeadConversionManager.getLeadMappingMetadata('Contact');

        for(Lead lead : leads){
            if(String.IsNotBlank(lead.N_mero_de_Documento__c)){
                dnis.add(lead.N_mero_de_Documento__c);
            }
        }
        Map<String, Contact> contactByDni = LeadConversionManager.getContactByDni(dnis);
        for(Lead lead : leads){
            if(contactByDni.containsKey(lead.n_mero_de_Documento__c)){
                Database.LeadConvert leadConvert = LeadConversionManager.leadConvertByLeadId.get(lead.Id);
                Contact contact = contactByDni.get(lead.n_mero_de_Documento__c);
                for(Mapping_Definition__mdt md : leadMappingContactMetadata){
                    if(String.IsNotBlank((String)lead.get(md.SourceField__c))){
                        contact.put(md.TargetField__c, (String)lead.get(md.SourceField__c));
                    }
                }
                contacts.add(contact);
                leadConvert.setContactId(contact.Id);
                leadConvert.setAccountId(contact.AccountId);
                LeadConversionManager.leadConvertByLeadId.put(lead.Id, leadConvert);
            }
        }
        if(!contacts.isEmpty()){
            update contacts;
        }
    }

    public static List<Mapping_Definition__mdt> getLeadMappingMetadata(String sObjectName){
        return [SELECT SourceField__c, TargetField__c FROM Mapping_Definition__mdt WHERE TargetObject__c = :sObjectName AND SourceObject__c = 'Lead'];
    }

    public static Database.LeadConvert createLeadConvert(String leadId){
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadId);
        lc.setConvertedStatus(LeadConversionManager.convertStatus.MasterLabel);
        return lc;
    }

    public static Map<String, Contact> getContactByDni(List<String> dnis){
        Map<String, Contact> contactByDni = new Map<String, Contact>(); 
        for(Contact contact : [SELECT Id, AccountId, N_mero_de_Documento__c FROM Contact WHERE N_mero_de_Documento__c IN :dnis]){
            contactByDni.put(contact.N_mero_de_Documento__c, contact);
        }
        return contactByDni;
    }

    public static List<Database.LeadConvertResult> convertLeads(){
        return Database.convertLead(LeadConversionManager.leadConvertByLeadId.values());
    }

    public static String convertUniqueLead(Lead lead){
        LeadConversionManager.processMapping(new List<Lead>{lead});
        String contactId;
        if(LeadConversionManager.contactIdByLeadId.containsKey(lead.Id)){
            contactId = LeadConversionManager.contactIdByLeadId.get(lead.Id);
        } 
        return contactId;
    }
}