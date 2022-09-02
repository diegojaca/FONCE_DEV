/**
 * @description       : Static Class to include helpers
 * @author            : juangabriel.duarte@s4g.es 
 * @group             : 
 * @last modified on  : 07-12-2022
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
**/
global class S4GUtils {

    /**
     * Verify if the fields has been changed
     * @param  l   SObject Record
     * @param  old SObject Record
     * @param  fields String[] with the field names
     * @return     Boolean
     */
    public static Boolean isChanged(SObject so, SObject old, String[] fields){

        for(String field : fields){
            if(so.get(field) != old.get(field)){
                return true;
            }
        }

        return false;
    }

    /**
     * Verify if the fields has been changed
     * @param  l   SObject Record
     * @param  old SObject Record
     * @param  fields String field name
     * @return     Boolean
     */
    public static Boolean isChanged(SObject so, SObject old, String field){
        return isChanged(so,old,new String[]{field});
    }

    /**
     * Retrieve dependent picklist values
     * @param  Schema.sObjectField dependToken
     * @return Map<String, List<String>>
     */
    public static Map<String, List<String>> getDependentPicklistValues(Schema.sObjectField dependToken) {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        if (controlToken == null) {
            return new Map<String, List<String>>();
        }

        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries;
        if(control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }

        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<String,List<String>> dependentPicklistValues = new Map<String,List<String>>();
        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                List<String> base64chars =
                        String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue =
                            (controlEntries == null
                                    ?   (Object) (index == 1)
                                    :   (Object) (controlEntries[index].isActive() ? controlEntries[index].getValue() : null)
                            );
                    Integer bitIndex = index / 6;
                    if (bitIndex > base64chars.size() - 1) {
                        break;
                    }
                    Integer bitShift = 5 - Math.mod(index, 6);
                    if  (controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
                        continue;
                    if (!dependentPicklistValues.containsKey((String) controlValue)) {
                        dependentPicklistValues.put((String) controlValue, new List<String>());
                    }
                    dependentPicklistValues.get((String) controlValue).add(entry.getValue());
                }
            }
        }
        return dependentPicklistValues;
    }

    /**
     * @description This method will return a list of API names for an object
     * @param soApiName object APIName
     * @param returnCustomFields whether or not to return custom fields in sobject
     * @param returnStandardFields whether or not to return standard fields in sobject
     * @return List of field APINames
     */
    public static List<String> getAllFieldsInSObject(String soApiName, Boolean returnCustomFields, Boolean returnStandardFields) {
       
        return getAllFieldsInSObject(soApiName, returnCustomFields, returnStandardFields, false);
    }

    /**
     * @description This method will join strings into one comma separated with ' to be used in an in statement in SOQL
     * @param stringsToJoin List of strings to join
     * @return Strings joined
     */
    public static String joinStringsForInStatement(List<String> stringsToJoin) {
        return '\'' + String.join(stringsToJoin, '\',\'') + '\'';
    }

    /**
    * @description This method will return a list of API names for an object validating if it´s editable
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 06-09-2022 
    * @param soApiName 
    * @param returnCustomFields 
    * @param returnStandardFields 
    * @return List<String> 
    **/
    public static List<String> getAllFieldsInSObject(String soApiName, Boolean returnCustomFields, Boolean returnStandardFields, Boolean onlyEditable) {

        List<String> fieldsToReturn = new List<String>();

        Map<String, SObjectField> fieldsMap = Schema.describeSObjects(new List<String>{
                soApiName
        }).get(0).fields.getMap();

        for (String fieldName : fieldsMap.keySet()) {

            DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();

            //If onlyEditable is false, return all fields
            if(!onlyEditable || fieldDescribe.isUpdateable()){

                if (returnCustomFields && fieldDescribe.isCustom()) {
                    fieldsToReturn.add(fieldDescribe.getName());
                } else if (returnStandardFields && !fieldDescribe.isCustom()) {
                    fieldsToReturn.add(fieldDescribe.getName());
                }
            }
        }
        return fieldsToReturn;
    }

    /**
    * @description Return Label of Sobject by Id
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 07-01-2022 
    * @param sObjectId 
    * @return String 
    **/
    public static String getSObjectLabelById(Id sObjectId){
        return sObjectId.getSObjectType().getDescribe().getLabel();
    }

    /**
    * @description Get recordtipe id by developer name and sobject name
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 07-12-2022 
    * @param soApiName 
    * @param rtDevName 
    * @return STring 
    **/
    public static STring getRecordTypeIdByDevName(String soApiName, String rtDevName){
        return Schema.getGlobalDescribe().get(soApiName).getDescribe().getRecordTypeInfosByDeveloperName()
        .get(rtDevName).getRecordTypeId();
    }
}