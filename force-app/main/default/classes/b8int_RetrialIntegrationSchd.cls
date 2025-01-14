public without sharing class b8int_RetrialIntegrationSchd implements Schedulable, Database.AllowsCallouts {
    public void execute(SchedulableContext sc) {
        Id jobId = b8int_RetrialIntegrationService.executeNextRetrialIntModel();
        if(jobId == null) {
            b8int_RetrialIntegrationService.setNextRetrialIntSchedule();
        }
        b8int_RetrialIntegrationService.deleteOldSchedule();
    }
}