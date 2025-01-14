public with sharing class EmailTemplateSelector {
	public static EmailTemplateSelector instance;
	public static EmailTemplateSelector getInstance() {
		if (instance == null) {
			instance = new EmailTemplateSelector();
		}
		return instance;
	}

	public List<EmailTemplate> getByDeveloperName(Set<String> emailTemplateDevNameSet) {
		return [
			SELECT Id, Body, Subject, DeveloperName, HtmlValue, TemplateType
			FROM EmailTemplate
			WHERE DeveloperName IN :emailTemplateDevNameSet
				AND IsActive = true
		];
	}
}