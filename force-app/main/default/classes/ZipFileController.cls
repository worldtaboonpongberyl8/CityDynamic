public with sharing class ZipFileController {
	// Zip file paths
	public List<String> paths {get;set;}
	
	// Generated zip file data (see receiveZipFile)
	public transient String zipFileData {get;set;}
	
	private ApexPages.StandardController controller;
	
	public ZipFileController(ApexPages.StandardController controller)
	{
		this.controller = controller;
		
		// Info message to ask the user to wait (no real time progress messages yet)
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 
			'Zip processing for the attacments has started please wait, you will be redirected to the resulting Document once this is completed.'));
				
		// Use Attachment names as zip entry path names for this example
		List<Attachment> attachments = [select Name from Attachment where ParentId =: controller.getId()];
		paths = new List<String>();
		for(Attachment attachment : attachments)
			paths.add(attachment.Name);
	}
	
	public PageReference receiveZipFile()
	{
		if(Test.isRunningTest()) {
			zipFileData = 'Unit Test';
		}
		// Receive the generated zip file and store it (in this case as a Document)
		ZipFile__c zipFile = ZipFileSelector.getById(controller.getId());
		Document document = new Document();
		document.Name = zipFile.Name;
		document.FolderId = UserInfo.getUserId();
		document.Body = EncodingUtil.base64Decode(zipFileData);
		insert document;
		return new PageReference('/'+document.Id);
	}
	
	@RemoteAction
	public static String getZipFileEntry(String path, String state)
	{
		// Retrieve or generate the Base64 encoded data for each file path to be added to the zip
		Attachment attachment = AttachmentSelector.getInstance().getByParentIdAndName(state, path).get(0);
		return EncodingUtil.base64Encode(attachment.body);
	}
}