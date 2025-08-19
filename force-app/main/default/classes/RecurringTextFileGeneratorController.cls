public with sharing class RecurringTextFileGeneratorController {
    @AuraEnabled
    public static String createRecurringTextFileAndDowdload(Id recordId) {
        try {
            String contentRecurring = '';
            Set<Id> opportunityIdSet = new Set<Id>();
            List<ContentVersion> contentVersionToCreate = new List<ContentVersion>();

            // Fetch Project and associated Opportunities
            Map<Id, Project__c> projectMap = ProjectSelector.getInstance().getProjectWithOppMapById(new Set<Id>{recordId});
            Project__c projectById = projectMap.get(recordId);
            List<Opportunity> opportunityList = projectById.Opportunities__r;
            if(opportunityList == null || opportunityList.isEmpty()){
                throw new AuraHandledException('no Opportunity to generate'); 
            }else{
                for (Opportunity opp : opportunityList) {
                    opportunityIdSet.add(opp.Id);
                }
    
                // Get remaining amounts and recurring text for each opportunity
                Map<Id, Decimal> remainingAmountMapByOppId = OpportunityPaymentService.getInstance().findOpportunityPaymentRemainingAmountMap(opportunityIdSet);
                Map<Id, String> recurringOpportunityTextMapByFieldset = OpportunityService.getInstance().getOpportunityTextMapByFieldset(opportunityList);
    
                for (Opportunity opp : opportunityList) {
                    String remainingAmountText = String.valueOf(remainingAmountMapByOppId.get(opp.Id));
                    String recurringText = recurringOpportunityTextMapByFieldset.get(opp.Id);
                    contentRecurring += recurringText + remainingAmountText + '\n';
                }
    
                // Create a ContentVersion record for the generated text
                if (!String.isBlank(contentRecurring)) {
                    ContentVersion conVer = new ContentVersion();
                    conVer.Origin = 'H';
                    conVer.PathOnClient = 'RecurringSummary.txt';
                    conVer.Title = 'Recurring Summary';
                    conVer.VersionData = Blob.valueOf(contentRecurring);
                    contentVersionToCreate.add(conVer);
                }
    
                if (!contentVersionToCreate.isEmpty()) {
                    List<Database.SaveResult> resultContentVersion = ContentVersionService.getInstance().insertContentVersions(contentVersionToCreate);
                    Set<Id> cvIdSet = new Set<Id>();
    
                    for (Database.SaveResult sr : resultContentVersion) {
                        if (sr.isSuccess()) {
                            cvIdSet.add((Id) sr.getId());
                        } else {
                            for (Database.Error err : sr.getErrors()) {
                                throw new AuraHandledException('Failed to insert content: ' + err.getMessage());
                            }
                        }
                    }
    
                    if (!cvIdSet.isEmpty()) {
                        List<ContentVersion> contentVersions = ContentVersionSelector.getInstance().getByIdSetNoVersionData(cvIdSet);
                        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
    
                        for (ContentVersion contentVersion : contentVersions) {
                            contentDocumentLinks.add(
                                new ContentDocumentLink(
                                    LinkedEntityId = recordId,
                                    ContentDocumentId = contentVersion.ContentDocumentId,
                                    ShareType = 'V',
                                    Visibility = 'AllUsers'
                                )
                            );
                        }
    
                        List<Database.SaveResult> resultContentDocumentLinks = ContentDocumentLinkService.getInstance().insertContentDocumentLinks(contentDocumentLinks);
                        for (Database.SaveResult sr : resultContentDocumentLinks) {
                            if (!sr.isSuccess()) {
                                for (Database.Error err : sr.getErrors()) {
                                    throw new AuraHandledException('Failed to link content: ' + err.getMessage());
                                }
                            }
                        }
    
                        // Return download link (based on first doc only)
                        if (!contentVersions.isEmpty()) {
                            Id contentDocumentId = contentVersions[0].ContentDocumentId;
                            String downloadUrl = System.Url.getOrgDomainUrl().toExternalForm()
                                + '/sfc/servlet.shepherd/document/download/' + contentDocumentId;
                            return downloadUrl;
                        }
                    }
                }
            }
            return null;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }
}