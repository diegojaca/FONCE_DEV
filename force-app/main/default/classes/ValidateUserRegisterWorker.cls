/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 06-13-2022
 * @last modified by  : diego.jacanamijoy@s4g.es
**/
global without sharing class ValidateUserRegisterWorker extends AbstractWorker{

    private Set<String> cIFvalues = new Set<String>();
    private Set<String> emailvalues = new Set<String>();
    private Map<String,User> userByCif = new Map<String,User>();
    private Map<String,User> userByEmail = new Map<String,User>();
    private static final String EMAIL_LABEL = 'Email';
    private static final String DOCUMENT_NUMBER_LABEL = 'Número de documento';

    public ValidateUserRegisterWorker() {
        super(String.valueOf(ValidateUserRegisterWorker.class));
    }

    public override void bulkBeforeInsert(List<SObject> newRecords){
        prepareData(newRecords);
    }

    public override void beforeInsert(SObject so){
        checkDuplicateData((User)so);
    }
    
    /**
    * @description 
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-06-2022 
    * @param newRecords 
    **/
    public void prepareData(List<SObject> newRecords){

        for(User user: (List<User>) newRecords){

            this.cIFvalues.add(user.N_mero_de_Documento__c);
            this.emailvalues.add(user.Email);
        }

        //Get existing users
        for(User exUser: [SELECT N_mero_de_Documento__c, Email FROM User WHERE N_mero_de_Documento__c IN: cIFvalues OR Email IN: emailvalues]){
            userByCif.put(exUser.N_mero_de_Documento__c, exUser);
            userByEmail.put(exUser.Email, exUser);
        }
    }

    /**
    * @description Validate if there are duplicate users
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-07-2022 
    * @param user 
    **/
    public void checkDuplicateData(User user){

        if(userByCif.containsKey(user.N_mero_de_Documento__c)){
            throw new UserRegisterException(formatMessage(user, DOCUMENT_NUMBER_LABEL, user.N_mero_de_Documento__c, userByCif.get(user.N_mero_de_Documento__c).Id));
        }

        if(userByEmail.containsKey(user.Email)){
            throw new UserRegisterException(formatMessage(user, EMAIL_LABEL, user.Email, userByEmail.get(user.Email).Id));
        }
    }

    /**
    * @description format message with params
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-07-2022 
    * @param user 
    * @param duplicateField 
    * @param duplicateValue 
    * @param duplicateRecordId 
    * @return String 
    **/
    public String formatMessage(User user, String duplicateField, String duplicateValue, String duplicateRecordId){

        Profile profile = [SELECT Name FROM Profile WHERE Id =: user.ProfileId LIMIT 1];

        List<String> params = new List<String>{duplicateField, duplicateValue, user.N_mero_de_Documento__c, user.Email, Profile.Name, duplicateRecordId};
        return String.format(Label.REGISTER_DUPLICATE_ERROR, params);
    }

    public class UserRegisterException extends Exception {}
}