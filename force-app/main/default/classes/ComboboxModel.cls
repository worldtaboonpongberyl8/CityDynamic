public with sharing class ComboboxModel {
    @AuraEnabled
    public String label { get; set; }
    @AuraEnabled
    public String value { get; set; }
	@AuraEnabled
    public Boolean isDefault { get; set; }

    public ComboboxModel() {

    }
    
    public ComboboxModel(String label, String value) {
        this.label = label;
        this.value = value;
    }

	public ComboboxModel(String label, String value, Boolean isDefault) {
        this.label = label;
        this.value = value;
		this.isDefault = isDefault;
    }
}