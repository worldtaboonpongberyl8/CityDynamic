public with sharing class ContractTriggerHandler {
    public ContractTriggerHandler() {

    }
    public static ContractTriggerHandler instance;
    public static ContractTriggerHandler getInstance(){
        if (instance == null){
            instance = new ContractTriggerHandler();
        }
        return instance;
    }

    public Boolean isActive = true;
    public List<Contract> newRecords;
    public Map<Id, Contract> oldMap;

    public Boolean isTriggerActivated() {
        if (TriggerActivation__mdt.getInstance('ContractTrigger') != null) {
            return this.isActive && TriggerActivation__mdt.getInstance('ContractTrigger').isActive__c;
        }
        return this.isActive;
    }
    public void setParams(List<Contract> newRecords, Map<Id, Contract> oldMap) {
        this.newRecords = newRecords;
        this.oldMap = oldMap;
    }
    public void setBypass() {
        this.isActive = false;
    }

    public void clearBypass() {
        this.isActive = true;
    }

    public void executeBeforeInsert() {
        this.stampContractName();
    }
    public void executeBeforeUpdate(){
        this.checkFullyPaidStatusForContract();
    }
    public void executeAfterInsert() {
        this.updateClientOfferToMakeRelationship();
    }

    public void executeAfterUpdate() {
        this.stampCompleteContractStatusToOpp();
    }

    private void stampContractName(){
        ContractService service = ContractService.getInstance();
        service.stampContractName(this.newRecords);
    }

    private void updateClientOfferToMakeRelationship(){
        ContractService service = ContractService.getInstance();
        List<ClientOffer__c> clientOffers = service.makeRelationshipWithClientOffer(this.newRecords);
        update clientOffers;
    }
    private void checkFullyPaidStatusForContract(){
        ContractService service = ContractService.getInstance();
        List<Contract> filteredContract = new List<Contract>();
       
        for (Contract contract : this.newRecords){
            Contract oldContract = this.oldMap.get(contract.Id);
                if (oldContract.Status != contract.Status && contract.Status == 'Signed Contract'){
                    filteredContract.add(contract);
                }
        }
        if(!filteredContract.isEmpty()){
            Map<Id,Boolean> checkFullyPaidStatusForCompleteContractMapByContractId = service.checkFullyPaidStatusForCompleteContract(filteredContract);
            for (Contract contract : filteredContract){
                    Boolean resultCheckStatus = checkFullyPaidStatusForCompleteContractMapByContractId.get(contract.Id) == null ? true : false;
                    if(!resultCheckStatus){
                        contract.addError(' Contract can not be updated if Contract Payment Status is not fully paid');    
                }  
            }
        }
    }
    private void stampCompleteContractStatusToOpp(){
        ContractService service = ContractService.getInstance();
        List<Contract> filteredContract = new List<Contract>();
        for (Contract contract : this.newRecords){
            Contract oldContract = this.oldMap.get(contract.Id);
                if (oldContract.Status != contract.Status && contract.Status == 'Signed Contract'){
                    filteredContract.add(contract);
                }
        }
        if(!filteredContract.isEmpty()){
            List<Opportunity> opportunities = service.stampCompleteContractStatusToOpp(filteredContract);
            update opportunities;
        }
    }
}