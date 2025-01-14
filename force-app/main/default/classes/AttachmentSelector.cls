public with sharing class AttachmentSelector {
    public static AttachmentSelector instance;

    public static AttachmentSelector getInstance() {
        if (instance == null) {
            instance = new AttachmentSelector();
        }
        return instance;
    }

	public List<Attachment> getByParentIdSet(Set<Id> parentIdSet){
		return [
			SELECT Id, Name, Body, ParentId, Parent.Name 
			FROM Attachment 
			WHERE ParentId IN: parentIdSet
		];
	}
	
	public List<Attachment> getByParentIdAndNameSet(Id parentId, Set<String> nameSet){
		return [
			SELECT Id, Name, Body, ParentId, Parent.Name 
			FROM Attachment 
			WHERE ParentId =: parentId AND (Name IN: nameSet)
		];
	}
	
	public List<Attachment> getByParentIdAndName(Id parentId, String name){
		return [
			SELECT Id, Name, Body, ParentId, Parent.Name 
			FROM Attachment 
			WHERE ParentId =: parentId AND Name =: name
		];
	}
}