public with sharing class ClientOfferService {
    public static ClientOfferService instance;

    public static ClientOfferService getInstance() {
        if (instance == null) {
            instance = new ClientOfferService();
        }
        return instance;
    }

    public List<ClientOffer__c> stampOriginalCostFromPromotionMasters(List<ClientOffer__c> clientOffers) {
        PromotionMasterSelector promotionMasterSelector = PromotionMasterSelector.getInstance();
        Set<Id> promotionMasterIds = new Set<Id>();
        for (ClientOffer__c clientOffer : clientOffers) {
            promotionMasterIds.add(clientOffer.PromotionMaster__c);
        }
        Map<Id, PromotionMaster__c> promotionMasterMapById = promotionMasterSelector.getPromotionMasterMapById(
            promotionMasterIds
        );
        for (ClientOffer__c clientOffer : clientOffers) {
            if (clientOffer.PromotionMaster__c != null) {
                PromotionMaster__c selectedPromotionMaster = promotionMasterMapById.get(clientOffer.PromotionMaster__c);
                clientOffer.OriginalCost__c = selectedPromotionMaster.PromotionCost__c;
            }
        }
        return clientOffers;
    }
}