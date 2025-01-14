public with sharing class PojjamanIntegrationScheduler implements Schedulable {

	public final String jobName = 'Job Scheduler: Integrate Data to Pojjaman';

	public static PojjamanIntegrationScheduler instance;
	public static PojjamanIntegrationScheduler getInstance() {
		if (instance == null) {
			instance = new PojjamanIntegrationScheduler();
		}
		return instance;
	}

	public String runSchedule() {
		return runSchedule('');
	}

	public String runSchedule(String CRON_EXP) {
		List<CronTrigger> conTriggerList = [
			SELECT Id
			FROM CronTrigger
			WHERE CronJobDetail.Name = :jobName
		];
		for ( CronTrigger conTrigger : conTriggerList ) {
			System.AbortJob(conTrigger.Id);
		}

		// Default: Daily Starts at : 23:00
		CRON_EXP = CRON_EXP != '' ? CRON_EXP : '0 0 23 1/1 * ? *';
		return System.schedule(jobName, CRON_EXP, new PojjamanIntegrationScheduler());
	}


    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CreateCustomerApiCalloutBatch(), 50);
    }
}