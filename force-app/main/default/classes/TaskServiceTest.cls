@isTest
public with sharing class TaskServiceTest {
    @isTest
	static void generateTaskTest(){
		TaskService service = TaskService.getInstance();
		Test.startTest();
			Task task = service.generateTask('Subject', 'Description', null);
		Test.stopTest();
		System.assertEquals('Subject', task.Subject);
		System.assertEquals('Description', task.Description);
		System.assertEquals(null, task.WhatId);
	}
}