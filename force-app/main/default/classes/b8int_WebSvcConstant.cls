public without sharing class b8int_WebSvcConstant {
    public enum WebSvcError {UNAUTEN_EXCEPTION, WEBSRV_EXCEPTION} 
    
	// http content type supported
	public static final String HEADER_CONTENT_TYPE = 'Content-Type';
	public static final String HEADER_ACCEPT_TYPE = 'Accept';
	public static final String HEADER_BASICAUTH = 'Authorization';
	public static final String HEADER_X_API_KEY = 'x-api-key';
    
    public static final String DEFAULT_EXCEPTION_PREFIX = 'Exception thrown during execution of web service';
	public static final String DEFAULT_HOST_NOTFOUND = 'Unable to connect to server. Host not found.';
	public static final String DEFAULT_INTERNAL_SERVER = 'Internal Sever Error.';

    // public static final Map<WebSvcError, String> WEB_SVC_ERROR_MESSAGE = new Map<WebSvcError, String>{
	// 	WebSvcError.UNAUTEN_EXCEPTION => 'Permission Denied', // HTTP Status 401
	// 	WebSvcError.WEBSRV_EXCEPTION => DEFAULT_EXCEPTION_PREFIX + '; {0}'
	// };

	// public static final Map<Integer, String> HTTP_STATUS_MESSAGE = new Map<Integer, String>{
	// 	400 => '(Status 400) The request contains an error not align on business scenarios, please verify your request.',
	// 	401 => '(Status 401) Permission Denied. The security access token used has expired or is invalid, please refresh token or obtain valid token.',
	// 	404 => '(Status 404) Unable to connect to target server. The resource you are looking for might have been removed, had its name changed, or is temporarily unavailable. please contact your administrator.',
	// 	500 => '(Status 50X) An error has occurred within target server, so the request couldn’t be completed, please contact your administrator.',
	// 	502 => '(Status 502) Unable to connect to target server. Web server received an invalid response while acting as a gateway or proxy server, please contact your administrator.',
	// 	999 => 'Unhandle error has occurred'
	// };

    public static final Map<b8int_BaseHttpRequest.ContentType, String> HTTP_CONTENT_TYPE = new Map<b8int_BaseHttpRequest.ContentType, String>{
		b8int_BaseHttpRequest.ContentType.XML => 'application/xml; charset=UTF-8',
		b8int_BaseHttpRequest.ContentType.XMLTEXT => 'text/xml; charset=UTF-8',
		b8int_BaseHttpRequest.ContentType.JSON => 'application/json; charset=UTF-8',
		b8int_BaseHttpRequest.ContentType.IMAGE => 'image/*',
		b8int_BaseHttpRequest.ContentType.URLENCODED => 'application/x-www-form-urlencoded',
		b8int_BaseHttpRequest.ContentType.ODATA => 'application/json;odata=nometadata',
		b8int_BaseHttpRequest.ContentType.ODATAVERBOSECONTENT => 'application/json;odata=verbose'
	};

	// public static final Map<b8int_BaseHttpRequest.ContentType, String> HTTP_ACCEPT_TYPE = new Map<b8int_BaseHttpRequest.ContentType, String>{
	// 	b8int_BaseHttpRequest.ContentType.XML => 'application/xml',
	// 	b8int_BaseHttpRequest.ContentType.XMLTEXT => 'text/xml',
	// 	b8int_BaseHttpRequest.ContentType.JSON => 'application/json',
	// 	b8int_BaseHttpRequest.ContentType.IMAGE => 'image/*',
	// 	b8int_BaseHttpRequest.ContentType.URLENCODED => 'application/x-www-form-urlencoded',
	// 	b8int_BaseHttpRequest.ContentType.ODATA => 'application/json;odata=nometadata',
	// 	b8int_BaseHttpRequest.ContentType.ODATAVERBOSECONTENT => 'application/json;odata=nometadata'
	// };
}