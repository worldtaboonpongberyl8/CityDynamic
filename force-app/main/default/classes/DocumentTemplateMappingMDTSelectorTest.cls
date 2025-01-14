@isTest
public with sharing class DocumentTemplateMappingMDTSelectorTest {
    @isTest 
	static void getByObjAPIAndLangAndTemplateMappingTypeTest(){
		Test.startTest();
		DocumentTemplateMappingMDTSelector selector = DocumentTemplateMappingMDTSelector.getInstance();
		List<DocumentTemplateMapping__mdt> result = selector.getByObjAPIAndLangAndTemplateMappingType(null,null,null);
		Test.stopTest();
	}

	@isTest 
	static void getByTemplateAndMappingTypeTest(){
		Test.startTest();
		DocumentTemplateMappingMDTSelector selector = DocumentTemplateMappingMDTSelector.getInstance();
		List<DocumentTemplateMapping__mdt> result = selector.getByTemplateAndMappingType(null);
		Test.stopTest();
	}
}