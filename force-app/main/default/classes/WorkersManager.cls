/**
 * http://s4g.es/en/
 */
global without sharing class WorkersManager{
	private enum TDTMOption {
        NPSP,
        Custom,
        All,
        SOBJ,
		Worker
    }

	/**
	 * Determine if all workers should be skipped
	 */
	private static Boolean avoidAllWorkersExecution = false;

	/**
    * Save the AbstractWorker instances by theirs ids
    */
    private static Map<String, AbstractWorker> workerByID = new Map<String, AbstractWorker> ();
	
	/**
     * This Map contains the Apex classes that asked for a worker deactivation during the transaction period
     */
    private static Map<String, Set<String>> workerDementorsMap = new Map<String, Set<String>>();
 
    /**
     * This method executes every worker asociated to an Object.
     */ 
    public static void execute (AbstractWorker worker) {
		worker = getWorkerInstance(worker); 

		if(WorkersManager.workerIsEnabled(worker.getWorkerID())) {

    			//-- fill data Worker variables with Trigger Data
    			if(Trigger.new != null) worker.newRecords = Trigger.new;
    			if(Trigger.newMap != null) worker.newRecordsMap = Trigger.newMap;
    			if(Trigger.old != null) worker.oldRecords = Trigger.old;
    			if(Trigger.oldMap != null) worker.oldRecordsMap = Trigger.oldMap;
				
		        if(Trigger.isBefore) {

		            // Call the bulk before to handle any caching of data and enable bulkification
		            worker.bulkBefore(Trigger.new);

					switch on Trigger.operationType {

						when BEFORE_INSERT {

							worker.bulkBeforeInsert(Trigger.new);
							for(SObject so : Trigger.new) {
								worker.beforeInsert(so);
							}
						}

						when BEFORE_UPDATE {

							worker.bulkBeforeUpdate(Trigger.old, Trigger.new);
							for(SObject so : Trigger.old) { 
								worker.beforeUpdate(so, Trigger.newMap.get(so.Id)); 
							}
						}


						when BEFORE_DELETE {

							worker.bulkBeforeDelete(Trigger.old);
							for(SObject so : Trigger.old) { 
								worker.beforeDelete(so); 
							}
						}
					}

		            //-- finally
		            worker.andFinallyBefore();

		        } else {

		            // Call the bulk before to handle any caching of data and enable bulkification
		            worker.bulkAfter(Trigger.new);

					switch on Trigger.operationType {
						
						when AFTER_INSERT {

							worker.bulkAfterInsert(Trigger.new);
							for(SObject so : Trigger.new) { 
								worker.afterInsert(so); 
							}
						}

						when AFTER_UPDATE {

							worker.bulkAfterUpdate(Trigger.old, Trigger.new);
							for(SObject so : Trigger.old) { 
								worker.afterUpdate(so, Trigger.newMap.get(so.Id)); 
							}
						}

						when AFTER_DELETE {

							worker.bulkAfterDelete(Trigger.old);
							for(SObject so : Trigger.old) { 
								worker.afterDelete(so); 
							}
						}

						when AFTER_UNDELETE {

							worker.bulkAfterUndelete(Trigger.new);
							for(SObject so : Trigger.new) { 
								worker.afterUndelete(so); 
							}
						}
					}

		            //-- finally
		            worker.andFinallyAfter();
		        }
    	}
    }    

	/**
	 * getWorkerInstance NPSP instancia dos veces el worker (before y after). Si no se guarda la instancia,
	 * se perderán todos los valores no estáticos.
	 * @param  worker worker description
	 * @return        return description
	 */
	private static AbstractWorker getWorkerInstance (AbstractWorker worker) {
        String workerId = worker.getworkerId();
        AbstractWorker result = null;

        if (WorkersManager.workerByID.containsKey (workerId)) {
            result = WorkersManager.workerByID.get(workerId);
        }else {
            result = worker;
            WorkersManager.workerByID.put(workerId, worker);
        }

        return result;
    }


	private static void avoidTDTM (TDTMOption pkgOption, String optionName, Boolean disable, String requestorID) {
        for (npsp__Trigger_Handler__c th : npsp.TDTM_Config_API.getCachedRecords()) {
            switch on pkgOption {
                when  NPSP {
                    if (!th.npsp__User_Managed__c) {
                        manageWorkerStatus(th, disable, requestorID);
                    }
                }
                when Custom {
                    if (String.isNotBlank (optionName) && th.npsp__Class__c.startsWithIgnoreCase (optionName + '.')) {
                        manageWorkerStatus(th, disable, requestorID);
                    }
                }
                when All {
                    th.npsp__Active__c = !disable;
                }
                when SOBJ {
                    if (String.isNotBlank (optionName) && th.npsp__Object__c.equalsIgnoreCase(optionName)) {
                        manageWorkerStatus(th, disable, requestorID);
                    }
                }
				when Worker{
					if (String.isNotBlank (optionName) && th.npsp__Class__c.equalsIgnoreCase(optionName)) {
                        manageWorkerStatus(th, disable, requestorID);
                    }
				}
            }
        }
    }

	private static void manageWorkerStatus(npsp__Trigger_Handler__c th, Boolean disable, String requestorID){
		if(!disable){
			removeWorkerDementor(th.npsp__Class__c, requestorID);
			if(!workerHasDementors(th.npsp__Class__c)){
				th.npsp__Active__c = true;
			}
		}else{
			addWorkerDementor(th.npsp__Class__c, requestorID);
			th.npsp__Active__c = false;
		}
	}

	/**
 	 * This method turns on/off the specified funtionality.
 	 * 
 	 * @param String workerId: Worker Class ID.
 	 * @param Boolean disable.
	 */
    global static void avoidWorkerExecution(String workerId, String requestorID, Boolean disable) {
		avoidTDTM (TDTMOption.Worker, workerId, disable, requestorID);
    }


	/**
 	 * This method turns on/off the specified funtionality.
 	 * 
 	 * @param String sobjectName: Salesforce Object technical name.
 	 * @param Boolean disable.
	 */
    global static void avoidWorkersExecutionPerObject(String sobjectName, String requestorID, Boolean disable) {
        avoidTDTM (TDTMOption.SOBJ, sobjectName, disable, requestorID);
    }


	/**
	 * Tell me if a worker is active
	 *
	 * @params String workerId
	 * @return Boolean
	 */
	global static Boolean workerIsEnabled(String workerId){
		Boolean thEnabled = false;
		for (npsp__Trigger_Handler__c th : npsp.TDTM_Config_API.getCachedRecords()) {
			if (th.npsp__Class__c  == workerId) {
                thEnabled = th.npsp__Active__c;
            }
		}
		return  !WorkersManager.avoidAllWorkersExecution && thEnabled;
	}

	/**
     * TAKE TOO MUCH CARE USING THIS METHOD - IT WILL TO INACTIVATE ALL THE ORGANIZATION WORKERS!
	 * Turns on / off all workers for then current execution
	 */
	global static void avoidAllWorkersExecution(Boolean disable) {
		avoidTDTM (TDTMOption.All, null, disable, null);
	}

	/**
     * It Indicates if the given workerID has Dementors that blocks the worker execution
     * @param  workerID workerID description
     * @return          return description
     */
    private static Boolean workerHasDementors(String workerID){
        if(workerDementorsMap.containsKey(workerID)){
            Set<String> dementors = workerDementorsMap.get(workerID);
            return dementors.size() > 0;
        }
        return false;
    }

    private static void addWorkerDementor(String workerID, String apexClassName){
        if (workerDementorsMap.containsKey(workerID)) {
            workerDementorsMap.get(workerID).add(apexClassName);
        } else {
            workerDementorsMap.put(workerID, new Set<String>{apexClassName});
        }
    }

    private static void removeWorkerDementor(String workerID, String apexClassName){
        if (workerDementorsMap.containsKey(workerID)) {
            workerDementorsMap.get(workerID).remove(apexClassName);
        }
    }

}