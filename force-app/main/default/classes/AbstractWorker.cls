/**
 * http://s4g.es/en/
 * 
 * This is the Base Abstract Workers class. It contains all the methods that could be used from a trigger initialization.
 * This class has the base workers functionality and handle all the events for triggers.
 * All the available data from Trigger is accesible [NEW RECORDS - OLD RECORDS].
 *
 */
global virtual inherited sharing class AbstractWorker extends npsp.TDTM_Runnable {

    /**
    * SObject api name
    */
    private String sObjectName = '';

    /* YOUR BASE CLASS RECEIVES ALL THE TRIGGER CONTEXT VARIABLES - OLD CONTEXT */
	//¿¿Protected?
	global List<SObject> oldRecords = new List<SObject>();
	global Map<Id, SObject> oldRecordsMap = new Map<Id, SObject>(); 

	/* YOUR BASE CLASS RECEIVES ALL THE TRIGGER CONTEXT VARIABLES - NEW CONTEXT */
	global List<SObject> newRecords = new List<SObject>();
	global Map<Id, SObject> newRecordsMap = new Map<Id, SObject>();

	/**
	 * Worker identifier
	 */
	private String WORKER_ID = '';

	//----------------------------------------------------------------------------------------------------------------------------------------
	//-- CONSTRUCTOR
	//----------------------------------------------------------------------------------------------------------------------------------------
	/**
	 * @description This constructor will set WORKER_ID for this worker
	 * @param workerid worker id is the worker name
	 */
	global AbstractWorker(String workerid) {
		this.WORKER_ID = workerid;	
	}

	/**
	 * Returns the worker ID
	 * @return String Worker ID
	 */
	global virtual String getWorkerID(){
		return this.WORKER_ID;
	}


	/** 
    * TDTM method overrided
    */ 
    global override npsp.TDTM_Runnable.DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, npsp.TDTM_Runnable.Action triggerAction,
        Schema.DescribeSObjectResult objResult) {
        
            this.sObjectName = objResult != null ? objResult.getName() : '';
            if (String.isBlank (getWorkerID())) {
				//if(UtilsErrorManagement.isStoringErrors()){
				//	insert UtilsErrorManagement.createError('TDTM_Runnable', ConstantsHelper.ERROR_TYPE_ERROR, Label.ErrorTDTMRunnable, null, null);
				//}
            } else if (Bypasser__c.getInstance().Disable_Triggers__c) {
				//insert UtilsErrorManagement.createError('TDTM_Runnable', ConstantsHelper.ERROR_TYPE_WARNING, Label.WarningErrorRunnable, null, null);
                //System.debug(LoggingLevel.WARN, getWorkerID() + ' '+ Label.WarningErrorRunnable);
            } else {
                WorkersManager.execute(this);
            } 

      return new npsp.TDTM_Runnable.DmlWrapper();
    }



	//-----------------------------------------------------------------------------------------------------------------------------------------
	//---------------------------------------------------BEFORE TRIGGER EVENT METHODS----------------------------------------------------------
	//-----------------------------------------------------------------------------------------------------------------------------------------
	
	/**
	 * Executes bulk processing on Before events.
	 * This method runs on before, no specifies if it's insert, update or deletion.
	 */
	global virtual void bulkBefore(List<SObject> newRecords){
	}

	/**
	 * Executes processing.
	 * This method must be used on Bulk Before Insert.
	 */
	global virtual void bulkBeforeInsert(List<SObject> newRecords){	
	}

    /**
     * This method is called iteratively for each record to be inserted during a BEFORE
     * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
     */
    global virtual void beforeInsert(SObject so){
    }

	/**
	 * Executes processing.
	 * This method must be invoked in Bulk Before Update.
	 */
	global virtual void bulkBeforeUpdate(List<SObject> oldRecords, List<SObject> newRecords){
	}

    /**
     * This method is called iteratively for each record to be updated during a BEFORE
     * trigger.
     */
    global virtual void beforeUpdate(SObject oldSo, SObject so){
    }
		
	/**
	 * Executes processing.
	 * This method must be invoked in Bulk Before Deletion.
	 */
	global virtual void bulkBeforeDelete(List<SObject> oldRecords){
	}

    /**
     * This method is called iteratively for each record to be deleted during a BEFORE
     * trigger.
     */
    global virtual void beforeDelete(SObject so){
    }
		
	/**
	 * This method is commontly used to commplete any progress made on before process
	 */
	global virtual void andFinallyBefore(){
	}


	//-----------------------------------------------------------------------------------------------------------------------------------------
	//---------------------------------------------------AFTER TRIGGER EVENT METHODS-----------------------------------------------------------
	//-----------------------------------------------------------------------------------------------------------------------------------------

	/**
	 * Executes processing.
	 * This method runs on after, no specifies if it's insert, update or deletion
	 */
	global virtual void bulkAfter(List<SObject> newRecords){
	}

	/**
	 * Executes processing.
	 * This method must be invoked in Bulk After Insert.
	 */
	global virtual void bulkAfterInsert(List<SObject> newRecords){
	}

    /**
     * This method is called iteratively for each record inserted during an AFTER
     * trigger. Always put field validation in the 'After' methods in case another trigger
     * has modified any values. The record is 'read only' by this point.
     */
    global virtual void afterInsert(SObject so){
    }
		
	/**
	 * Executes processing.
	 * This method must be invoked in Bulk After Update.
	 */
	global virtual void bulkAfterUpdate(List<SObject> oldRecords, List<SObject> newRecords){
	}

    /**
     * This method is called iteratively for each record updated during an AFTER
     * trigger.
     */
    global virtual void afterUpdate(SObject oldSo, SObject so){
    }
		
	/**
	 * Executes processing.
	 * This method must be invoked in Bulk After Delete.
	 */
	global virtual void bulkAfterDelete(List<SObject> oldRecords){
	}

    /**
     * This method is called iteratively for each record deleted during an AFTER
     * trigger.
     */
    global virtual void afterDelete(SObject so){
    }
		
	/**
	 * Executes processing.
	 * This method must be invoked in Bulk After Undelete.
	 */
	global virtual void bulkAfterUndelete(List<SObject> newRecords){
	}

    /**
     * This method is called iteratively for each record undeleted during an AFTER
     * trigger.
     */
    global virtual void afterUndelete(SObject so){
    }
		
	/**
	 * This method is commontly used to commplete any progress made on after process
	 */
	global virtual void andFinallyAfter(){
	}

}