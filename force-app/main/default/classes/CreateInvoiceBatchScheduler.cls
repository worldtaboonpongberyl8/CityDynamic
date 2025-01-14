public with sharing class CreateInvoiceBatchScheduler implements Schedulable {
	public final String jobName = 'Job Scheduler: Create Invoice Related Records Files and Send Emails';

	public static CreateInvoiceBatchScheduler instance;
	public static CreateInvoiceBatchScheduler getInstance() {
		if (instance == null) {
			instance = new CreateInvoiceBatchScheduler();
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

		// Default: Daily Starts at : 14:00
		CRON_EXP = CRON_EXP != '' ? CRON_EXP : '0 0 14 1/1 * ? *';
		return System.schedule(jobName, CRON_EXP, new CreateInvoiceBatchScheduler());
	}

	public void execute(SchedulableContext sc) {
		ID processId = Database.executeBatch(new CreateInvoiceBatch(), 50);
	}
}