public class RecurringTextFileGeneratorScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        List<Project__c> projectList = [
            SELECT Id
            FROM Project__c
        ];

		// There is some query,dml in for loop. However, since Project__c is not bulk object, so it is not a problem.
        for (Project__c project : projectList) {
            try {
                generateRecurringTextFile(project.Id);
            } catch (Exception e) {
                System.debug('Error while generating file for Project ' + project.Id + ': ' + e.getMessage());
            }
        }
    }

    private static void generateRecurringTextFile(Id projectId) {
        String contentRecurring = '';
        Set<Id> opportunityIdSet = new Set<Id>();
        List<ContentVersion> contentVersionToCreate = new List<ContentVersion>();

        Map<Id, Project__c> projectMap = ProjectSelector.getInstance().getProjectWithOppMapById(new Set<Id>{projectId});
        Project__c projectById = projectMap.get(projectId);
        List<Opportunity> opportunityList = projectById.Opportunities__r;

        if (opportunityList == null || opportunityList.isEmpty()) {
            return; // No opportunity, skip this project
        }

        for (Opportunity opp : opportunityList) {
            opportunityIdSet.add(opp.Id);
        }

        Map<Id, Decimal> remainingAmountMapByOppId = OpportunityPaymentService.getInstance().findOpportunityPaymentRemainingAmountMap(opportunityIdSet);
        Map<Id, String> recurringOpportunityTextMapByFieldset = OpportunityService.getInstance().getOpportunityTextMapByFieldset(opportunityList);

        for (Opportunity opp : opportunityList) {
            String remainingAmountText = String.valueOf(remainingAmountMapByOppId.get(opp.Id));
            String recurringText = recurringOpportunityTextMapByFieldset.get(opp.Id);
            contentRecurring += recurringText + remainingAmountText + '\n';
        }

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
                    continue; // Skip this one, already handled in log
                }
            }

            if (!cvIdSet.isEmpty()) {
                List<ContentVersion> contentVersions = ContentVersionSelector.getInstance().getByIdSetNoVersionData(cvIdSet);
                List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();

                for (ContentVersion contentVersion : contentVersions) {
                    contentDocumentLinks.add(
                        new ContentDocumentLink(
                            LinkedEntityId = projectId,
                            ContentDocumentId = contentVersion.ContentDocumentId,
                            ShareType = 'V',
                            Visibility = 'AllUsers'
                        )
                    );
                }

                ContentDocumentLinkService.getInstance().insertContentDocumentLinks(contentDocumentLinks);
            }
        }
    }
}