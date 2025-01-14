public with sharing class DataMaker {

	public static DataMaker instance;

	public DataMaker(){

	}

	public static DataMaker getInstance(){
		if (instance == null){
			instance = new DataMaker();
		}
		return instance;
	}
	public EmailTemplate createEmailTemplate(String name, String developerName, String templateType ,String subject){
		return new EmailTemplate(
			isActive = true,
			Name = name,
			DeveloperName = developerName,
			TemplateType = templateType,
			Subject = subject,
			HtmlValue = '<p>Hello World</p>',
			FolderId = UserInfo.getUserId()
		);
	}
	public WordContentMaster__c createWordContentMester(Id zipFileId){
		return new WordContentMaster__c(
			ZipFileMasterId__c = zipFileId
		);
	}
	public ZipFile__c createZipFile(String name, Id recordTypeId){
		return new ZipFile__c(
			Name = name,
			RecordTypeId = recordTypeId
		);
	}
	public Attachment createAttachment(String name ,Blob body, Id parentId){
		return new Attachment(
			Name = name,
			Body = body,
			ParentId = parentId
			);
	}
	public User createUser(String name, String lastName, String email, String profileName) {
		Profile userProfile = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
		return new User(
			Username = email,
			LastName = lastName,
			Email = email,
			Alias = name.substring(0, Math.min(name.length(), 8)), // Alias max length is 8
			ProfileId = userProfile.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			LanguageLocaleKey = 'en_US',
			UserRoleId = null,
			EmailEncodingKey = 'UTF-8'
		);
	}

	public Group createQueue(String queueName) {
		return new Group(
			Name = queueName,
			Type = 'Queue'
		);
	}
	public Account createAccount(Id recordTypeId, String accountName){
		return new Account(
			Name = accountName,
			RecordTypeId = recordTypeId,
			Phone = '0111111111'
		);
	}

	public Contact createContact(Id accountId,String firstName, String lastName, String email, String phone){
		return new Contact(
			AccountId = accountId,
			FirstName = firstName,
			LastName = lastName,
			Email = email,
			Phone = phone,
			MobilePhone = phone
		);
	}
	public PaymentMethod__c createPaymentMethod(Id receiptId ,String bankName, Decimal receivedAmount, String paymentType ,String term, Date paymentDate){
		return new PaymentMethod__c(
			PaymentReceipt__c = receiptId,
			ReceivedAmount__c  = Integer.ValueOf(receivedAmount),
			BankName__c = bankName,
			PaymentType__c = paymentType,
			Term__c= term ,
			PaymentDate__c = paymentDate
		);
	}
	public Opportunity createOpportunity(Id accountId , String forecastCategoryName ,String oppName , Date closeDate, String stageName,Id unitId,String quota,Id paymentTermMasterId , Id projectId){
		return new Opportunity(
			AccountId = accountId,
			ForecastCategoryName = forecastCategoryName,
			Name = oppName,
			CloseDate = closeDate,
			Project__c = projectId,
			Unit__c = unitId,
			Quota__c = quota,
			StageName = stageName,
			PaymentTermMaster__c = paymentTermMasterId
		);
	}
	public OpportunityPayment__c createOpportunityPayment(Id oppId, String term, Decimal amount, Date dueDate, Decimal order ){
		return new OpportunityPayment__c(
			Opportunity__c = oppId,
			Order__c = order,
			Amount__c = amount,
			DueDate__c = dueDate,
			Term__c = term,
			IsMasterData__c = true
		);
	}

	public PromotionOpportunity__c createPromotionOpportunity(Id oppId , Id promotionMasterId){
		return new PromotionOpportunity__c(
			Opportunity__c = oppId,
			PromotionMaster__c = promotionMasterId
		);
	}

	public GroupMember addUserToQueue(Id userId, Id queueId) {
		return new GroupMember(
			GroupId = queueId,
			UserOrGroupId = userId
		);
	}

	public QueueSObject addQueueToSObject(Id queueId, String sObjectType) {
		return new QueueSObject(
			QueueId = queueId,
			SobjectType = sObjectType
		);
	}

	public Lead createLead(String firstName, String lastName, String company, Id ownerId, String countryName) {
		return new Lead(
			FirstName = firstName,
			LastName = lastName,
			Company = company,
			OwnerId = ownerId,
			LeadCountry__c = countryName,
			Phone = '0111111111'
		);
	}

	public Lead createLeadAsUpload(String firstName, String lastName, String company, Id ownerId, String countryName) {
		return new Lead(
			FirstName = firstName,
			LastName = lastName,
			Company = company,
			OwnerId = ownerId,
			LeadCountry__c = countryName,
			LeadOrigin__c = 'Upload',
			IsAutoAssingment__c = true,
			Phone = '0111111111'
		);
	}

	public RoundRobinAssignment__c createRRAssignment(String queueName , Id userId , String targetObject) {
		return new RoundRobinAssignment__c(
			QueueName__c = queueName,
			LastAssignedUser__c = userId,
			TargetObject__c = targetObject
		);
	}
	public UnitType__c createUnitType(String unitTypeName, Id projectId){
		return new UnitType__c(
			Name = unitTypeName,
			Project__c = projectId
		);
	}
	public Project__c createProject(
		String name,
		String projectCode,
		String companyCode
	){
		return new Project__c(
			Name = name,
			ProjectCode__c = projectCode,
			CompanyCode__c = companyCode
		);
	}
	public Floor__c createFloor(String name, String code,Id projectId){
		return new Floor__c(
			Name = name,
			FloorCode__c = code,
			Project__c = projectId
		);
	}
	public Product2 createUnit(String name, String code,Id projectId,Id floorId, String status,Id unitTypeId){
		return new Product2(
			Name = name,
			ProductCode = code,
			Project__c = projectId,
			Floor__c = floorId,
			Family = 'None',
			UnitType__c = unitTypeId,
			Status__c = status
		);
	}
	public Pricebook2 createPricebook(String name, Id productId ){
		return new Pricebook2(
			Name = name,
			Product2__c = productId

		);
	}
	public ContentVersion createContentVersion(String title,String pathOnClient){
		return new ContentVersion(
			Title=title,
			PathOnClient=pathOnClient,
			VersionData=EncodingUtil.base64Decode('AA=='),
			Origin='H'
		);
	}
	public ContentDocumentLink createContentDocumentLink(Id linkedEntityId,Id contentDocumentId){
		return new ContentDocumentLink(
			LinkedEntityId = linkedEntityId,
			ContentDocumentId = contentDocumentId
		);
	}
	public PaymentTermMaster__c craetePaymentTermMaster(Id projectId , String name, String type, String quota, Decimal noOfInstallment){
		return new PaymentTermMaster__c (
			Name = name,
			Type__c = type,
			Quota__c = quota,
			Project__c = projectId,
			NoofInstallment__c = noOfInstallment,
			ActiveFrom__c = Date.newInstance(2024, 9, 12),
			ActiveTo__c = Date.newInstance(2030, 9, 12),
			DueDate__c = 25
		);
	}

	public PaymentTerm__c createPaymentTermLineItem(Id paymentTermMasterId , Decimal order, Decimal amount, Decimal percent,String term){
		return new PaymentTerm__c(
			PaymentTermMaster__c = paymentTermMasterId,
			Order__c = order,
			Amount__c = amount,
			Percent__c = percent,
			Term__c = term
		);
	}

	public PromotionMaster__c craeteActivePromotionMaster(Id projectId, Id unitId, String name,String source , String promotionType , String additionalDetail, String description, Decimal cost){
		return new PromotionMaster__c(
			Name = name,
			ActiveFrom__c = Date.newInstance(2024, 9, 12),
			ActiveTo__c = Date.newInstance(2044, 9, 12),
			Project__c = projectId,
			Unit__c = unitId,
			Source__c = source,
			PromotionType__c = promotionType,  //Discount (ส่วนลด), Premium (ของแถม)
			AdditionalDetail__c = additionalDetail,
			Description__c = description,
			PromotionCost__c = cost
		);
	}
	public PricebookEntry createPricebookEntries(Id productId , Integer tqPrice,Integer fqPrice ,Integer unitPrice){
		return new PricebookEntry(
			Product2Id = productId,
			TQUnitPrice__c = tqPrice,
			FQUnitPrice__c = fqPrice,
			UnitPrice = unitPrice
		);
	}
	public ClientOffer__c createClientOffer(Id promotionMasterId, Id opportunityId, Decimal cost ){
		return new ClientOffer__c(
			PromotionMaster__c = promotionMasterId,
			Opportunity__c = opportunityId,
			Cost__c = cost
		);
	}

	public CoBuyer__c createCoBuyer(Id opportunityId,Id accountId , String priorirty){
		return new CoBuyer__c(
			Customer__c = accountId,
			Opportunity__c = opportunityId,
			Priority__c = priorirty
		);
	}

	public Quote__c createQuote(Id opportunityId){
		Quote__c quote = new Quote__c(
			Opportunity__c = opportunityId,
			Status__c = 'Open'
		);
		return quote;
	}

	public Contract createContract(Id opportunityId, Id accountId){
		Contract contract = new Contract(
			Opportunity__c = opportunityId,
			AccountId = accountId,
			Status = 'Draft'
		);
		return contract;
	}

	public Invoice__c createInvoice(Id opportunityId, Date dueDate, Date invoiceDate, Boolean doNotSendInvoice, String accountAddress){
		return new Invoice__c(
			Opportunity__c = opportunityId,
			InvoiceDate__c = invoiceDate,
			DueDate__c = dueDate,
			DoNotSendInvoice__c = doNotSendInvoice,
			AccountAddress__c = accountAddress
		);
	}

	public InvoiceLineItem__c createInvoiceLineItem(Id invoiceId , Id oppPaymentId , Decimal amount, Date dueDate, String status){
		return new InvoiceLineItem__c(
			Invoice__c = invoiceId,
			OpportunityPayment__c = oppPaymentId,
			Amount__c = amount,
			DueDate__c = dueDate,
			Status__c = status
		);
	}

	public PaymentReceipt__c craeteReceipt(Id opportunityId, Date receiveDate){
		return new PaymentReceipt__c(
			Opportunity__c = opportunityId,
			ReceivedDate__c = receiveDate
		);
	}

	public PaymentReceiptLineItem__c createReceiptLineItem(Id receiptId , Id oppPaymentId , Id invoiceLineId, Decimal receiveAmount, String status){
		return new PaymentReceiptLineItem__c(
			PaymentReceipt__c = receiptId,
			OpportunityPayment__c = oppPaymentId,
			InvoiceLineItem__c = invoiceLineId,
			ReceivedAmount__c = receiveAmount,
			Status__c = status
		);
	}

	public NameFormattingMasterData__c createNameFormattingMasterData(String objectName, String type, String purpose, String format, Integer currentRuuning, String docTemplateMappingType){
		return new NameFormattingMasterData__c(
			ObjectName__c = objectName,
			Type__c = type,
			RunningPurpose__c = purpose,
			RunningFormat__c = format,
			CurrentRunningNumber__c = currentRuuning,
			DocumentTemplateMappingType__c = docTemplateMappingType
		);
	}

	public Bank__c createBank(String bankAccountNumber, String bankName, String bankBranch, String bankAddress, String swiftCode, Id projectId, Boolean isActive, Boolean isDefault, Boolean isUsedInPaymentGateWay){
		return new Bank__c(
			BankAccountNumber__c = bankAccountNumber,
			BankName__c = bankName,
			BankBranch__c = bankBranch,
			BankAddress__c = bankAddress,
			SWIFTCode__c = swiftCode,
			Project__c = projectId,
			IsActive__c = isActive,
			IsDefault__c = isDefault,
			IsUsedInPaymentGateway__c = isUsedInPaymentGateWay
		);
	}

	public InvoiceSetting__c createInvoiceSetting(){
		return new InvoiceSetting__c(
			DueDate__c = 5,
			CancelReasonByOppCancel__c = 'Auto Cancelled by System'
		);
	}

}