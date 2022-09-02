/**
 * @description       : 
 * @author            : diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 06-13-2022
 * @last modified by  : diego.jacanamijoy@s4g.es
**/
global without sharing class UserDataToContactWorker extends AbstractWorker {

    private List<Contact> contactsToUpdate = new List<Contact>();
    private Map<String, String> contactFieldByUserField = new Map<String, String>();
    private List<Schema.FieldSetMember> registerPageFields;

    global UserDataToContactWorker() {
        super(String.valueOf(UserDataToContactWorker.class));
    }

    public override void bulkAfterInsert(List<SObject> newRecords) {
        this.prepareData(newRecords);
    }

    public override void andFinallyAfter() {

        if (!this.contactsToUpdate.isEmpty()) {
            List<String> contactsToUpdate = new List<String>();
            for (Contact contact : this.contactsToUpdate) {
                contactsToUpdate.add(JSON.serialize(contact));
            }
            UserDataToContactWorker.updateContacts(contactsToUpdate);
        }
    }

    /**
    * @description Init mthod to prepare bulk data
    * @author diego.jacanamijoy@s4g.es | 06-13-2022 
    * @param newRecords listo of new user records
    **/
    public void prepareData(List<SObject> newRecords) {
        this.registerPageFields = SObjectType.User.fieldSets.RegisterPage.getFields();
        this.buildUserToFieldConfigMap();

        for (User user : (List<User>) newRecords) {

            //Check if has related contact
            if (String.isNotBlank(user.ContactId)) {
                this.copyUserDataToContact(user, new Contact(Id = user.ContactId));
            }
        }
    }

    /**
    * @description copy data from user field to correspondent contac field
    * @author diego.jacanamijoy@s4g.es | 06-13-2022
    * @param user user record
    * @param contact contac record
    **/
    private void copyUserDataToContact(User user, Contact contact) {

        for (Schema.FieldSetMember userField : this.registerPageFields) {
            //Check if there is config for user field api name
            if (this.contactFieldByUserField.containsKey(userField.getFieldPath())) {
                //Copy field data to contact field
                contact.put(this.contactFieldByUserField.get(userField.getFieldPath()), user.get(userField.getFieldPath()));
            }
        }

        if (!CONSTANTS.COMMUNITY_USER_TYPES.get(0).equals(user.UserType)) {
            //Set Consultar_duplicados__c = true, for search duplicates in other proccess
            contact.Consultar_duplicados__c = true;
            //Unlink generica account
            contact.AccountId = null;
        }

        this.contactsToUpdate.add(contact);
    }

    /**
    * @description Build map of user field to contac field config
    * @author diego.jacanamijoy@s4g.es | 06-13-2022 
    **/
    private void buildUserToFieldConfigMap() {

        for (UserFieldToContact__mdt config : [SELECT ContactFieldApiName__c, UserFieldApiName__c FROM UserFieldToContact__mdt]) {
            this.contactFieldByUserField.put(config.UserFieldApiName__c, config.ContactFieldApiName__c);
        }
    }

    @Future
    public static void updateContacts(List<String> contacts) {
        List<Contact> contactsToUpdate = new List<Contact>();
        for (String contactSerialized : contacts) {
            contactsToUpdate.add((Contact) JSON.deserialize(contactSerialized, Contact.class));
        }
        update contactsToUpdate;
    }

}