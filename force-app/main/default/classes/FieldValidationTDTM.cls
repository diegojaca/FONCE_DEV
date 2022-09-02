/**
 * @description       : 
 * @author            : Juan Gabriel Duarte
 * @group             : 
 * @last modified on  : 05-04-2021
 * @last modified by  : Juan Gabriel Duarte
 * Modifications Log 
 * Ver   Date         Author                Modification
 * 1.0   05-04-2021   Juan Gabriel Duarte   Initial Version
**/
global with sharing class FieldValidationTDTM extends AbstractWorker{
    global FieldValidationTDTM(){
        super(String.valueOf(FieldValidationTDTM.class));
    }

    public override void beforeInsert(SObject so){
        so = DataValidationHelper.validateFields(so);
    }

    public override void beforeUpdate(SObject oldSo, SObject so){
        checkFieldstoValidate(oldSo, so);
    }

    /**
     * @description This method checks whether the fields to be validated have 
     * changed and launches the validation if so.
     * @param  oldso oldso description
     * @param  so    so description
     */
    private static void checkFieldstoValidate(SObject oldso, SObject so){        
        String fields = 'N_mero_de_Documento__c';
        //if(Utils.isChangedField(so, oldSo, fields)){
        if((String) so.get('N_mero_de_Documento__c') != (String) oldso.get('N_mero_de_Documento__c')){
            so = DataValidationHelper.validateFields(so);
        }        
        
    }

    
}