public with sharing class UserSelector {

	public static UserSelector instance;
	public static UserSelector getInstance(){
		if (instance == null){
			instance = new UserSelector();
		}
		return instance;
	}

	public User getUserById(Id recordId){
		return [
			SELECT Id, Name, Email, IsActive, Profile.Name
			FROM User
			WHERE Id =: recordId
			LIMIT 1
		];
	}

	public Map<Id,User> getUserMapById(Set<Id> userIds){
		return new Map<Id,User>([
			SELECT Id, Name, Email, IsActive, Profile.Name
			FROM User
			WHERE Id IN: userIds
		]);
	}
}