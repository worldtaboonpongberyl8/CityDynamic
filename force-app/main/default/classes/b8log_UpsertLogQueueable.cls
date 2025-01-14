public class b8log_UpsertLogQueueable implements Queueable {
    List<b8log_IntegrationLogModel> intLogModelsForInsert;
    List<b8log_IntegrationLogModel> intLogModelsForUpdate;
    List<b8log_ApplicationLogModel> appLogModelsForInsert;

    List<Attachment> logAttachments;

    public b8log_UpsertLogQueueable(List<b8log_IntegrationLogModel> intLogModelsForInsert,
                                    List<b8log_IntegrationLogModel> intLogModelsForUpdate,
                                    List<b8log_ApplicationLogModel> appLogModelsForInsert) {
        this.intLogModelsForInsert = intLogModelsForInsert;
        this.intLogModelsForUpdate = intLogModelsForUpdate;
        this.appLogModelsForInsert = appLogModelsForInsert;
    }

    public void execute(QueueableContext context) {
        b8log_UpsertLogService.immidiateInsertLogs(this.intLogModelsForInsert, this.intLogModelsForUpdate, this.appLogModelsForInsert);
        this.intLogModelsForInsert.clear();
        this.intLogModelsForUpdate.clear();
        this.appLogModelsForInsert.clear();
    }
}