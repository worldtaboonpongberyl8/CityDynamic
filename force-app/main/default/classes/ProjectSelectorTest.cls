@isTest
private class ProjectSelectorTest {

	@TestSetup
	static void makeData(){
		DataMaker dataMaker = DataMaker.getInstance();
		Project__c testProject = dataMaker.createProject('Test Project', 'AA01', 'CD');
		insert testProject;
	}

	@isTest
	static void getProjectByIdTest() {
		Project__c testProject = [SELECT Id,Name FROM Project__c WHERE ProjectCode__c ='AA01'];
		Map<Id,Project__c> projectMap = ProjectSelector.getInstance().getProjectById(new Set<Id>{testProject.Id});
		System.assertEquals(testProject, projectMap.get(testProject.Id));
	}

	@isTest
	static void getProjectMapByProjectCodeTest(){
		Project__c testProject = [SELECT Id,Name,ProjectCode__c FROM Project__c WHERE ProjectCode__c ='AA01'];
		Map<String,Project__c> projectMap = ProjectSelector.getInstance().getProjectMapByProjectCode(new Set<String>{testProject.ProjectCode__c});
		System.assertEquals(testProject, projectMap.get(testProject.ProjectCode__c));
	}
}