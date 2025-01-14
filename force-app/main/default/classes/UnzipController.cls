public with sharing class UnzipController {

	public String unzippedState {get;set;}
	public FileWrapper fileWrapper { get; set; }

    public UnzipController() {
    	fileWrapper = new FileWrapper();
		StaticResource targetStaticResource = [SELECT Id, Body, SystemModStamp, Name, ContentType FROM StaticResource WHERE Name = 'SampleContractWord'];
		fileWrapper.name = targetStaticResource.Name;
		fileWrapper.size = EncodingUtil.base64Encode(targetStaticResource.Body);
		fileWrapper.type = targetStaticResource.ContentType;
    }

	@RemoteAction
	public static String receiveZipFileEntry(String filename, String path, String data, String state) {
		if(state=='')
		{
			ZipFile__c zipFile = new ZipFile__c();
			zipFile.Name = filename;
			insert zipFile;
			state = zipFile.Id;
		}
		
		Attachment attachment = new Attachment();
		attachment.Body = EncodingUtil.base64Decode(data);
		attachment.Name = path;
		attachment.ParentId = state;
		insert attachment;
		
		return state;		
	}
    
    public class FileWrapper{
		public String name {get;set;}
		public String size {get;set;}
		public String type {get;set;}
	}
}