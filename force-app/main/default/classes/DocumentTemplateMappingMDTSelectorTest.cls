@isTest
public with sharing class DocumentTemplateMappingMDTSelectorTest {
    @isTest
	static void getByObjAPIAndLangAndTemplateMappingTypeTest(){
		List<DocumentTemplateMapping__mdt> results = DocumentTemplateMappingMDTSelector.getInstance().getByObjAPIAndLangAndTemplateMappingType(
			'Contract',
			'TH',
			'Contract'
		);
		System.assert(results.size() > 0);
	}

	@isTest
	static void getByTemplateAndMappingTypeTest(){
		List<DocumentTemplateMapping__mdt> results = DocumentTemplateMappingMDTSelector.getInstance().getByTemplateAndMappingType('Contract');
		System.assert(results.size() > 0);
	}
}