public with sharing class DocumentGeneratorController {
    @AuraEnabled(cacheable=true)
	public static List<ComboboxModel> getLanguages(String templateMappingType) {
		List<DocumentTemplateMapping__mdt> docTemplateMdts = DocumentTemplateMappingMDTSelector.getInstance().getByTemplateAndMappingType(templateMappingType);
		Set<String> languageSet = new Set<String>();
		for (DocumentTemplateMapping__mdt docTemplateMdt : docTemplateMdts) {
			languageSet.add(docTemplateMdt.Language__c);
		}

		List<ComboboxModel> selectedModels = new List<ComboboxModel>();
		for (String language : languageSet) {
			selectedModels.add(
				new ComboboxModel( language, language )
			);
		}
		return selectedModels;
	}
}