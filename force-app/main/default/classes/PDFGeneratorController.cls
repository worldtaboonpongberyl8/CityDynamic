public with sharing class PDFGeneratorController {

    @AuraEnabled
	public static void createPDFFile(
		String recordId,
		String pdfPageName,
		String purpose,
		String templateMappingType,
		String fieldAPISaveToExisting
	){
		List<Id> recordIds = new List<Id>{recordId};

		String objectAPIName = ((Id) recordId).getSObjectType().getDescribe().getName();

		List<NameFormattingMasterData__c> nameFormattingMasterDatas = NameFormattingMasterDataSelector.getInstance()
			.getByObjTypePurposeDocTemplate(objectApiName, 'Format', purpose, templateMappingType);

		Map<Id, String> fileNameMapWithRecordId = RunningNumberUtility.getInstance().generateReplacedFormatName(
			nameFormattingMasterDatas.get(0), recordIds, objectApiName
		);

		List<ContentDocumentLink> contentDocLinks = PDFUtility.getInstance().createPdfFileToRecord(
			pdfPageName,
			fileNameMapWithRecordId,
			recordIds,
			null
		);

		if(!contentDocLinks.isEmpty()){
			ContentDocumentService.getInstance().saveToExistingFile(recordId, contentDocLinks.get(0), fieldAPISaveToExisting);
		}

	}
}