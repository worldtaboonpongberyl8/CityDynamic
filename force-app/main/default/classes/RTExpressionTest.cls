@isTest
public with sharing class RTExpressionTest {
	@isTest
	static void testPrior() {
		Account oldRecord = new Account();
		oldRecord.AccountSource = 'Before';

		Account newRecord = new Account();
		newRecord.AccountSource = 'After';
		
		String expression = 'PRIORVALUE(AccountSource) == \'Before\' AND AccountSource == \'After\'';
		RT_Expression actualExpression = RTExpression.parseRTExpress(expression, newRecord, oldRecord);
	}
	
	@isTest
	static void testIsNotBlank() {
		Account account = new Account();
		account.NumberOfEmployees = 5;
		account.AccountSource = '1';
		RT_Expression expression = RTExpression.parseRTExpress('AccountSource != \'\' && AccountSource != null', account);
		System.assertEquals(true, expression.evalBool());
	}


	@isTest
	static void test() {
		String expression = 'CRM_ApprovalTopic__c == \'New Customer\' && CRM_ApprovalStep__c == \'Pending for DM Approve\'';
		Map<String, Object> newObjMap = new Map<String, Object>();
		newObjMap.put('CRM_ApprovalStep__c', 'Pending for DM Approve');
		newObjMap.put('CRM_ApprovalTopic__c', 'New Customer');
		RT_Expression rt = new RT_Expression(expression, newObjMap);
		System.assertEquals(true, rt.evalBool());
	}

	@isTest
	static void testMassExpression() {
		System.debug(LoggingLevel.INFO, 'getCpuTime ' + Limits.getCpuTime());
		DateTime start = System.now();
		List<Account> accounts = new List<Account>();
		for (Integer i = 0; i < 100; i++) {
			Account newAccount = new Account();
			newAccount.NumberOfEmployees = Math.mod(i, 20);
			if(Math.mod(i, 2) == 0) newAccount.AccountSource = 'Email';
			newAccount.AccountSource = 'Web';
			accounts.add(newAccount);
		}
		
		for (Account newAccount : accounts) {
			RT_Expression expression = RTExpression.parseRTExpress('AccountSource != \'Web\' && NumberOfEmployees < 10', newAccount);
			if(newAccount.Accountsource != 'Web' && newAccount.NumberOfEmployees < 10) {
				System.assertEquals(true, expression.evalBool());
			} else {
				System.assertEquals(false, expression.evalBool());
			}
		}
		Decimal diff = Decimal.valueOf(System.now().getTime() - start.getTime());
		System.debug(LoggingLevel.INFO, diff/ 1000);
		System.debug(LoggingLevel.INFO, 'getCpuTime ' + Limits.getCpuTime() + ' ' + Limits.getLimitCpuTime());
	}

	@isTest
	static void testParseExpression() {
		Account account = new Account();
		account.NumberOfEmployees = 5;
		account.AccountSource = 'Web';
		RT_Expression expression = RTExpression.parseRTExpress('AccountSource != \'Web\' && NumberOfEmployees < 10', account);
		System.assertEquals(false, expression.evalBool());

		account.NumberOfEmployees = 9;
		account.AccountSource = 'Email';
		expression = RTExpression.parseRTExpress('AccountSource != \'Web\' && NumberOfEmployees < 10', account);
		System.assertEquals(true, expression.evalBool());

		account.NumberOfEmployees = 11;
		account.AccountSource = 'Email';
		expression = RTExpression.parseRTExpress('AccountSource != \'Web\' && NumberOfEmployees < 10', account);
		System.assertEquals(false, expression.evalBool());
	}

	@isTest
	static void testIsChange() {
		Account oldRecord = new Account();
		oldRecord.AccountSource = 'Web';
		oldRecord.Name = 'Name1';
		Account newRecord = new Account();
		newRecord.AccountSource = 'Other';
		newRecord.Name = 'Name2';

		Map<String, sObject> sobjMap = new Map<String, sObject>();
		sobjMap.put('oldRecord', oldRecord);
		sobjMap.put('newRecord', newRecord);

		RT_Expression expression = RTExpression.parseRTExpress('IsChange(Name) && newRecord.AccountSource == \'Other\'', sobjMap);
		System.assertEquals(true, expression.evalBool());

		System.assertEquals(true, new RT_Expression('oldRecord.AccountSource != newRecord.AccountSource', new Map<String, Object> {
			'oldRecord.AccountSource' => oldRecord.get('AccountSource'),
			'newRecord.AccountSource' => newRecord.get('AccountSource')
		}).evalBool());

		
		System.assertEquals(true, new RT_Expression('oldRecord.AccountSource != newRecord.AccountSource && newRecord.AccountSource == \'Other\'', new Map<String, Object> {
			'oldRecord.AccountSource' => oldRecord.AccountSource,
			'newRecord.AccountSource' => newRecord.AccountSource
		}).evalBool());
	}

	@isTest
	static void testMinusValue() {
		Account account = new Account();
		account.AnnualRevenue = -2.5;
		RT_Expression expression = RTExpression.parseRTExpress('AnnualRevenue <= -2', account);
		System.assertEquals(true, expression.evalBool());
		
		expression = RTExpression.parseRTExpress('AnnualRevenue >= -2', account);
		System.assertEquals(false, expression.evalBool());
	}

	@isTest
	static void testContructorParamString() {
		RT_Expression newRecord = new RT_Expression('a = b');
	}

	@isTest
	static void testContructorParamMathContext() {
		RT_Expression newRecord = new RT_Expression('a = b', new RT_Expression.MathContext(7, RoundingMode.HALF_EVEN));
	}

	@isTest
	static void testSetPrecision() {
		Account account = new Account();
		account.NumberOfEmployees = 5;
		account.AccountSource = 'Web';
		RT_Expression expression = RTExpression.parseRTExpress('AccountSource != \'Web\' && NumberOfEmployees < 10', account);
		expression.setPrecision(2);
	}

	@isTest
	static void testSetRoundingMode() {
		Account account = new Account();
		account.NumberOfEmployees = 5;
		account.AccountSource = 'Web';
		RT_Expression expression = RTExpression.parseRTExpress('AccountSource != \'Web\' && NumberOfEmployees < 10', account);
		expression.setRoundingMode(RoundingMode.HALF_EVEN);
	}

	@isTest
	static void testWith() {
		Account account = new Account();
		account.NumberOfEmployees = 5;
		account.AccountSource = 'Web';
		RT_Expression expression = RTExpression.parseRTExpress('AccountSource != \'Web\'', account);
		expression.with('NumberOfEmployees', 10);
	}

	@isTest
	static void testGetExpressionTokenizer() {
		Account account = new Account();
		account.NumberOfEmployees = 5;
		account.AccountSource = 'Web';
		RT_Expression expression = RTExpression.parseRTExpress('AccountSource != \'Web\' && NumberOfEmployees < 10', account);
		expression.getExpressionTokenizer();
	}

	@isTest
	static void testToRPNr() {
		Account account = new Account();
		account.NumberOfEmployees = 5;
		account.AccountSource = 'Web';
		RT_Expression expression = RTExpression.parseRTExpress('AccountSource != \'Web\' && NumberOfEmployees < 10', account);
		expression.toRPN();
	}

	@isTest
	static void testGetDeclaredVariables() {
		Account account = new Account();
		account.NumberOfEmployees = 5;
		account.AccountSource = 'Web';
		RT_Expression expression = RTExpression.parseRTExpress('AccountSource != \'Web\' && NumberOfEmployees < 10', account);
		expression.getDeclaredVariables();
	}

	@isTest
	static void testGetDeclaredOperators() {
		Account account = new Account();
		account.NumberOfEmployees = 5;
		account.AccountSource = 'Web';
		RT_Expression expression = RTExpression.parseRTExpress('AccountSource != \'Web\' && NumberOfEmployees < 10', account);
		expression.getDeclaredOperators();
	}

	@isTest
	static void testGetDeclaredFunctions() {
		Account account = new Account();
		account.NumberOfEmployees = 5;
		account.AccountSource = 'Web';
		RT_Expression expression = RTExpression.parseRTExpress('AccountSource != \'Web\' && NumberOfEmployees < 10', account);
		expression.getDeclaredFunctions();
	}

	@isTest
	static void testFquals() {
		Account account = new Account();
		account.NumberOfEmployees = 5;
		account.AccountSource = 'Web';
		RT_Expression expression = RTExpression.parseRTExpress('AccountSource != \'Web\' && NumberOfEmployees < 10', account);
		expression.equals(account);
	}

	@isTest
	static void testHashCode() {
		Account account = new Account();
		account.NumberOfEmployees = 5;
		account.AccountSource = 'Web';
		RT_Expression expression = RTExpression.parseRTExpress('AccountSource != \'Web\' && NumberOfEmployees < 10', account);
		expression.hashCode();
	}

	@isTest 
	static void parseRTExpressTest(){
		Test.startTest();
		Account oldRecord = new Account();
		oldRecord.AccountSource = 'Before';
		Account newRecord = new Account();
		newRecord.AccountSource = 'After';
		// test expression contains newRecord and oldRecord
		String expression = 'newRecord.AccountSource == \'Before\' AND oldRecord.AccountSource == \'After\'';
		RT_Expression actualExpression = RTExpression.parseRTExpress(expression, newRecord, oldRecord);
		// test expression contains ISCHANGE
		String expression2 = 'ISCHANGE(AccountSource)';
		RT_Expression actualExpression2 = RTExpression.parseRTExpress(expression2, newRecord, oldRecord);
		Test.stopTest();
	}
}