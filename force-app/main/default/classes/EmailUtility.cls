public without sharing class EmailUtility {
	public static EmailUtility instance;
	public static EmailUtility getInstance() {
		if (instance == null) {
			instance = new EmailUtility();
		}
		return instance;
	}

	public final String emailForOrgWide = 'citydynamic@beryl8.com';

	public Messaging.SingleEmailMessage getSingleEmail(
		Id orgWideId,
		EmailTemplate emailTemplate,
		List<String> toAddresses,
		List<String> ccAddresses,
		List<Messaging.EmailFileAttachment> emailFileAttachments,
		List<Id> ctVersionIds,
		Id recordId,
		Id contactId
	) {
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setTemplateId(emailTemplate.Id); // Replace with your actual template ID
		email.setToAddresses( toAddresses );
		email.setSaveAsActivity(false);

		// tempEmail.setEntityAttachments(new List<String>{'068BK000000ucVdYAI', '068BK000000ucaTYAQ'}); // คำสั่งนี้ไม่ count query เพิ่ม แต่ตอน get มันจะมีการ count query เพิ่ม
		if(orgWideId != null) {
			email.setOrgWideEmailAddressId(orgWideId);
		}

		if(ccAddresses != null && !ccAddresses.isEmpty()) {
			email.setCcAddresses(ccAddresses);
		}

		if(emailFileAttachments!= null && !emailFileAttachments.isEmpty()){
			email.setFileAttachments(emailFileAttachments);
		}

		if (ctVersionIds != null && !ctVersionIds.isEmpty() ){
			email.setEntityAttachments(ctVersionIds);
		}

		if(contactId != null){
			email.setTargetObjectId(contactId); // จะมีการส่ง email ไปหา contactId นี้ด้วย และต้องรับ Id จาก Object Contact เท่านั้น ถ้ามีการ setWhatId() ไม่งั้นจะพัง
		}

		if(recordId != null){
			email.setWhatId(recordId); // Set the related record ใช้คู่กับ setTargetObjectId() คือถ้ามี setTargetObjectId() ถึงจะใช้คำสั่ง setWhatId() ได้
		}

		return email;
	}

	public Messaging.SendEmailResult[] sendAllEmailMessage(List<Messaging.SingleEmailMessage> singleEmails){
		Messaging.SendEmailResult[] results;
		if(singleEmails == null || singleEmails.isEmpty()){
			return results;
		}

		results = Messaging.sendEmail(singleEmails, false);

		return results;
	}

    public Messaging.EmailFileAttachment getFileAttachment(String fileName, Blob body) {
        Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
        emailAttachment.setFileName( fileName );
        emailAttachment.setBody( body );
        return emailAttachment;
    }

	// ไม่ได้ทำการส่ง email จริงๆ แต่ทำการ fake ส่ง เพื่อที่จะได้ค่าของ email ที่มีการ replace field ต่างๆ เรียบร้อยแล้ว
	public void fakeSendEmails(List<Messaging.SingleEmailMessage> tempEmails){
		// create savepoint before executing statement
		Savepoint savePoint = Database.setSavepoint();

		// send the temporary email list
		Messaging.sendEmail(tempEmails);

		// rollback the transaction before commiting to database
		Database.rollback(savePoint);
	}

	// ใช้คู่กับ fakeSendEmails() เพื่อทำการส่ง email จริงๆ แบบไม่ทำการ count soql เพิ่ม
	// คำสั่ง renderStoredEmailTemplate(emailTemplateId, null, recordId); ไม่ต้อง setTargetObjectId() มันก็จะไม่ส่ง mail ไปหา Contact แต่จะมีการ count query เพิ่ม
	public Messaging.SingleEmailMessage getSingleEmailFromTempEmail(Messaging.SingleEmailMessage tempEmail,List<Id> ctVersionIds){
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setToAddresses(tempEmail.getToAddresses());
		email.setCcAddresses(tempEmail.getCcAddresses());
		email.setSubject(tempEmail.getSubject());
		email.setOrgWideEmailAddressId(tempEmail.getOrgWideEmailAddressId());

		if(String.isNotEmpty(tempEmail.getHTMLBody())){
			email.setHTMLBody(tempEmail.getHTMLBody());
		}
		if(String.isNotEmpty(tempEmail.getPlainTextBody())){
			email.setPlainTextBody(tempEmail.getPlainTextBody());
		}

		if(tempEmail.getFileAttachments() != null && !tempEmail.getFileAttachments().isEmpty()){
			email.setFileAttachments(tempEmail.getFileAttachments());
		}
		// email.setEntityAttachments(tempEmail.entityattachments); // คำสั่งนี้ count query เพิ่ม
		// email.setEntityAttachments(tempEmail.getEntityAttachments()); // คำสั่งนี้ count query เพิ่ม
		email.setEntityAttachments(ctVersionIds);
		return email;
	}
}