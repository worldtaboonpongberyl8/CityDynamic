/**
 * Phase2
 * Details:
 * - Add new class to be service of Task
 */
public class TaskService {

    public static TaskService instance;

	public static TaskService getInstance() {
		if (instance == null) {
			instance = new TaskService();
		}
		return instance;
	}

	/**
	 * Phase2
	 * Details:
	 * - Add new method to generate Task record with the detail
	 */
	public Task generateTask(String subject, String description, String whatId){
		return new Task(
			Subject = subject,
			Description = description,
			WhatId = whatId
		);
	}

}