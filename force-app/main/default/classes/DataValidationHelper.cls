/**
 * @description  : Auxiliary methods to validate values from fields (NIF, IBAN...)
 * @author       : S4G
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   04-09-2020   S4G   Initial Version
**/
public with sharing class DataValidationHelper {

	public static Map<String, Set<String>> docsToValidateByMethod = new Map<String, Set<String>>();

	private static String becasUserProfileId;

	/**
	* @description Validates configured fields for that object
	* @author S4G | 04-09-2020 
	* @param obj Object with fields to validate
	* @return SObject Object with field already validated
	**/
	public static SObject validateData(SObject obj){
		return validateFields(obj);
	}

    public static SObject validateFields(SObject obj){
		String objectType = obj.getSobjectType().getDescribe().getName();
		Boolean isValid = true;

		/** If is Contact or User of Becas Site, check document type with verifyNIF method */
		Boolean isContactOrUser = objectType =='Contact' || (objectType == 'User' && obj.get('ProfileId') == getBecasProfileId());

		/** For contact, it´s valid NIE or NIF document types */
        if(isContactOrUser && (String) obj.get('N_mero_de_Documento__c')!=null){
			String documentNumberAux = (String) obj.get('N_mero_de_Documento__c');
            isValid = DataValidationHelper.verifyNIF(documentNumberAux) || DataValidationHelper.verifyNIE(documentNumberAux);
        }else if(objectType=='Account' && (String) obj.get('N_mero_de_Documento__c')!=null ){
            isValid = DataValidationHelper.isValidCif( (String) obj.get('N_mero_de_Documento__c') );			            
        }

		if(!isValid){			
			//obj.put('N_mero_de_Documento__c', 'El Número de Documento no es válido!');
			obj.addError('El Número de Documento ' + (String) obj.get('N_mero_de_Documento__c') + ' no es válido!');
		}
		
		return obj;
    }

	/**
	* @description Validate size and structure from a NIF number
	* @author S4G | 04-09-2020 
	* @param num NIF value to validate
	* @return Boolean Result from NIF validation
	**/
	public static Boolean verifyNIF(String num){
      if(num.length() == 9 && num.substring(0, 1).isNumeric() && num.substring(8).isAlpha()){
        return (!String.isBlank(num) && isValidNifNie(num));
      }else{
        return false;
      }
    }

    /**
    * @description  Validate size and structure from a NIE number
    * @author S4G | 04-09-2020 
    * @param num NIF value to validate
    * @return Boolean Result from NIE validation
    **/
    public static Boolean verifyNIE(String num){
      if(num.length() == 9 && num.substring(0, 1).isAlpha() && num.substring(8).isAlpha()){
        return (!String.isBlank(num) && isValidNifNie(num));
      }else{
        return false;
      }
    }

	/**
	 * @description Validate Spanish Document Number (NIF or NIE)
	 * @param  nif NIF/NIE value to validate
	 * @return Boolean Result from NIE validation
	 */
	private static Boolean isValidNifNie(String nif){

		nif = nif.toUpperCase();
	   	
	   	String[] startChar = new String[]{'X','Y','Z'};  
	   	for(Integer i=0; i < startChar.size(); i++){
	   		if (nif.startsWith(startChar[i])){
		   		nif = nif.replaceFirst(startChar[i], String.valueOf(i));
		   	}
	   	}
		 
		Pattern nifPattern = Pattern.compile('(\\d{1,8})([TRWAGMYFPDXBNJZSQVHLCKEtrwagmyfpdxbnjzsqvhlcke])');
		Matcher m = nifPattern.matcher(nif);
		if(m.matches()){
			String letra = m.group(2);
			String letras = 'TRWAGMYFPDXBNJZSQVHLCKE';
			Integer dni = Integer.valueOf(m.group(1));
			dni = mod(String.valueOf(dni), 23);
			String reference = letras.substring(dni,dni+1);
			 
			if (reference.equalsIgnoreCase(letra)){
				return true;
			}else{
				return false;
			}
		}
		else{
			return false;
		}
	}

	/**
	 * @description Validate Spanish CIF
	 * @param  cif CIF value to validate
	 * @return Boolean Result from CIF validation
	 */
	public static Boolean isValidCif(String cif){
		cif = cif.toUpperCase();
		String[] myMap = new String[]{'J','A','B','C','D','E','F','G','H','I'};

		String[] myCif = cif.split('');

		if( !(cif.length()==9 
				&& !(myCif[0].isNumeric())
				&& (cif.substring(1, 8)).isNumeric()) ){
			return false;
		}

		Integer sumA = Integer.valueOf(myCif[2])
						+ Integer.valueOf(myCif[4])
						+ Integer.valueOf(myCif[6]);

		Integer sumB = 0;
		for( Integer i=1; i<=7; i=i+2){
			Integer b = Integer.valueOf(myCif[i])*2;
			if(b>=10){
				b = Integer.valueOf(String.valueOf(b).left(1)) 
					+ Integer.valueOf(String.valueOf(b).right(1));
			}
			sumB += b;
		}

		Integer sumC = sumA + sumB;
		Integer resE = Integer.valueOf(String.valueOf(sumC).right(1));
		Integer resD = resE==0 ? 0 : 10-resE;

		String start1 = 'KPQS'; // 'KPQSW' ? (en alguna documentacion se incluye W)
		String start2 = 'ABEH';
		try{
			if( start1.contains(myCif[0]) ){ //debe terminar por letra
				return myCif[8] == myMap[resD];
			}
			else if( start2.contains(myCif[0]) ){ // debe terminar por número
				return Integer.valueOf(myCif[8]) == resD;
			}
			else{ // puede terminar por letra o por número indistintamente
				return ( myCif[8] == myMap[resD] 
						|| Integer.valueOf(myCif[8]) == resD );
			}
		}catch(Exception e){
			return false;
		}
	}


	/**
     * @description Mod of big numbers, which can not be parsed to Integer or Long
     * @param  bigNumber Big number as String
     * @param  num       Number to realize mod
     * @return           mod of the big number
     */
    private static Integer mod (String bigNumber, Integer num) {
        if (String.isBlank(bigNumber)) {
            return null;
        }
        Integer res = 0;
        List<String> numbers = bigNumber.split('');
        if (String.isBlank(numbers[0])) {
            numbers.remove(0);
        }
        for (String n : numbers) {
            res = Math.mod((res * 10 + Integer.valueOf(n)), num);
        }
        return res;
    }


	/**
	* @description This methos return Profile Id of Becas portal Login
	* @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 08-29-2022 
	* @return String 
	**/
	private static String getBecasProfileId() {

		if (String.isBlank(becasUserProfileId)) {
			becasUserProfileId = [SELECT Id FROM Profile WHERE NAME =: Label.BECAS_USER_PROFILE LIMIT 1].Id;
		}
		return becasUserProfileId;
	}

    
}