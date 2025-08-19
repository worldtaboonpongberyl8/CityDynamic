global without sharing class ZipDocumentController {
	public String lightningHost {get;set;}
	public String recordId {get;set;}
	global String targetFileName {get;set;}
	public String fieldAPISaveToExisting {get;set;}
	public String remainingList {get;set;}
	public String remainingDocNameList {get;set;}
	public String remainingFieldAPISaveToExistingList {get;set;}
	// Zip file paths
	public List<String> paths {get;set;}

	// Generated zip file data (see receiveZipFile)
	public transient String zipFileData {get;set;}

	private ApexPages.StandardController controller;

	private string fileName(String fileName) {
		fileName = fileName.replace('\'', '\\\'') ;
		return fileName;
	}

	private string fileTitle(String fileName) {
		fileName = fileName.replace('\\\'', '\'') ;
		return fileName;
	}

	public ZipDocumentController(ApexPages.StandardController controller) {
		if (controller.getId() != null) {
			this.controller = controller;
			this.recordId = ApexPages.currentPage().getParameters().get('recordId');
			this.remainingList = ApexPages.currentPage().getParameters().get('remainingList');
			this.remainingDocNameList = ApexPages.currentPage().getParameters().get('remainingDocNameList');
			this.remainingFieldAPISaveToExistingList = ApexPages.currentPage().getParameters().get('remainingFieldAPISaveToExistingList');
			List<String> docNameList = this.remainingDocNameList.split(',');
			List<String> remaingFieldExistingFileList = this.remainingFieldAPISaveToExistingList.split(',');
			ZipFile__c targetZipFile = ZipFileSelector.getInstance().getById(controller.getId());
			this.targetFileName = this.fileName(docNameList[0]);

			if(this.targetFileName.contains('[COMMA]')){
				this.targetFileName = this.targetFileName.replaceAll('\\[COMMA\\]', ',');
			}
			if(this.targetFileName.contains('[AMPERSAND]')){
				this.targetFileName = this.targetFileName.replaceAll('\\[AMPERSAND\\]', '&');
			}

			docNameList.remove(0);

			fieldAPISaveToExisting = remaingFieldExistingFileList.get(0);
			remaingFieldExistingFileList.remove(0);


			List<String> keepRemainingValue = new List<String>();
			List<String> remainList = this.remainingList.split(',');
			for (String eachId : remainList) {
				if (!eachId.contains(this.controller.getId())) {
					keepRemainingValue.add(eachId);
				}
			}
			remainList.remove(0);

			if (keepRemainingValue.size() > 0) {
				this.remainingList = String.join(keepRemainingValue, ',');
			}
			else{
				this.remainingList = '';
			}
			if (docNameList.size() > 0) {
				this.remainingDocNameList = String.join(docNameList, ',');
			}
			else{
				this.remainingDocNameList = '';
			}
			if (remaingFieldExistingFileList.size() > 0) {
				this.remainingFieldAPISaveToExistingList = String.join(remaingFieldExistingFileList, ',');
			}
			else{
				this.remainingFieldAPISaveToExistingList = '';
			}
			// Info message to ask the user to wait (no real time progress messages yet)
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,
				'Zip processing for the attacments has started please wait, you will be redirected to the resulting Document once this is completed.'));

			// Use Attachment names as zip entry path names for this example
			List<Attachment> attachments = AttachmentSelector.getInstance().getByParentIdSet(new Set<Id>{controller.getId()});
			paths = new List<String>();
			for(Attachment attachment : attachments)
				paths.add(attachment.Name);
		}
	}

	public PageReference receiveZipFile(){
		// Receive the generated zip file and store it (in this case as a Document)
		Set<Id> zipFileIdSet = new Set<Id>();
		String remainPath = (String.isBlank(this.remainingList))? '':'&c__remainingList='+this.remainingList;
		String remainDocName = (String.isBlank(this.remainingDocNameList))? '':'&c__remainingDocNameList='+this.remainingDocNameList;
		String remainFieldAPI = (String.isBlank(this.remainingFieldAPISaveToExistingList))? '':'&c__remainingFieldAPISaveToExistingList='+this.remainingFieldAPISaveToExistingList;
		if(Test.isRunningTest()) {
			zipFileData = 'Unit Test';
		}
		ZipFile__c zipFile = ZipFileSelector.getInstance().getById(controller.getId());
		zipFileIdSet.add(zipFile.Id);
		ContentVersion ContVerFile = new ContentVersion();
		ContVerFile.VersionData = EncodingUtil.base64Decode(zipFileData);
		ContVerFile.Title = this.fileTitle(this.targetFileName);
		ContVerFile.ContentLocation= 's';
		ContVerFile.PathOnClient = zipFile.Name;
		insert ContVerFile;

		ContentVersion targetContentVersion = ContentVersionSelector.getInstance().getById(ContVerFile.Id);

		ContentDocumentLink contentDocLink = new ContentDocumentLink();
		contentDocLink.ContentDocumentId = targetContentVersion.ContentDocumentId;
		contentDocLink.LinkedEntityId = this.recordId;
		contentDocLink.ShareType = 'V';
		contentDocLink.Visibility = 'AllUsers';
		insert contentDocLink;

		saveToExistingFile(contentDocLink);

		ZipUtility.getInstance().deleteZipRecord(zipFileIdSet);

		PageReference retURL = new PageReference('/lightning/cmp/c__wordGenerator?c__recordId='+this.recordId+remainPath+remainDocName+remainFieldAPI);
		retURL.setRedirect(true);
		return retURL;
	}

	public PageReference redirectToLightningPage(){
		// Receive the generated zip file and store it (in this case as a Document)
		return new PageReference('/'+this.recordId);
	}

	@RemoteAction
	public static String getZipFileEntry(String path, String state)
	{
		// Retrieve or generate the Base64 encoded data for each file path to be added to the zip
		Attachment attachment = AttachmentSelector.getInstance().getByParentIdAndName(state, path).get(0);
		return EncodingUtil.base64Encode(attachment.body);
	}

	private void saveToExistingFile(ContentDocumentLink contentDocLink){
		if(this.fieldAPISaveToExisting == 'no'){
			return;
		}

		ContentDocumentService.getInstance().saveToExistingFile(this.recordId, contentDocLink, this.fieldAPISaveToExisting);
	}
}