public without sharing class b8int_SfdcSessionIdUtils {
    private static String sessionIdFromVFPage;
    
    public static string getSessionIdFromVfPage(){
        if (sessionIdFromVFPage!= null) {
            return sessionIdFromVFPage; 
        }
        PageReference visualforcePage = Page.b8int_SfdcSessionIdPage;
        String content;
        try{
            content = visualforcePage.getContent().toString();
        }
        catch(VisualforceException e){
            content='Start_Of_Session_Id'+userinfo.getSessionId()+'End_Of_Session_Id';
		}
        Integer s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length();
        Integer e = content.indexOf('End_Of_Session_Id');
        sessionIdFromVFPage = content.substring(s, e);
        return sessionIdFromVFPage;
    }
}