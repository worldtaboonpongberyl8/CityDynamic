public with sharing class RTExpression {
    public RTExpression() {

    }
    
    public static RT_Expression parseRTExpress(String expression, sObject obj) {
        Map<String, Object> newObjMap = new Map<String, Object>();
        Map<String, Object> fieldsToValue = obj.getPopulatedFieldsAsMap();

        for(String field : fieldsToValue.keySet()) {
            if(expression.containsIgnoreCase(field)) {
                if(fieldsToValue.get(field) instanceof SObject) { continue; }
                newObjMap.put(field, fieldsToValue.get(field));
            }
        }
        return new RT_Expression(expression, newObjMap);
    }


    public static RT_Expression parseRTExpress(String expression, sObject newRecord, sObject oldRecord) {
        Map<String, Object> newObjMap = new Map<String, Object>();
        Integer index = 0;
        while(expression.indexOf('newRecord.', index) >= 0) {
            String field = expression.substring(index).substringBetween('newRecord.', ' ');
            index = expression.indexOf('newRecord.', index);
            newObjMap.put('newRecord.'+field, newRecord.get(field));
            index = index + 1;
        }
        index = 0;
        while(expression.indexOf('oldRecord.', index) >= 0) {
            // system.debug('1');
            String field = expression.substring(index).substringBetween('oldRecord.', ' ');
            index = expression.indexOf('oldRecord.', index);
            newObjMap.put('oldRecord.'+field, oldRecord.get(field));
            index = index + 1;
        }

        while(expression.contains('ISCHANGE')) {
            // system.debug('2');
            String field = expression.substringBetween('ISCHANGE(', ')');
            expression = expression.replace('ISCHANGE('+field+')', 'oldRecord.'+field+' != newRecord.'+field);
            newObjMap.put('newRecord.'+field, newRecord.get(field));
            Object valueOfOldRecord =  oldRecord != null ? oldRecord.get(field) : null;
            newObjMap.put('oldRecord.'+field, valueOfOldRecord);
        }

        while(expression.contains('PRIORVALUE')) {
            // system.debug('3');
            String field = expression.substringBetween('PRIORVALUE(', ')').replaceAll( '\\s+', '');
            expression = expression.replace('PRIORVALUE('+field+')', 'oldRecord.'+field);
            Object valueOfOldRecord =  oldRecord != null ? oldRecord.get(field) : null;
            newObjMap.put('oldRecord.'+field, valueOfOldRecord);
        }

        // List<String> expressions = expression.split(' ');
        Map<String, Object> fieldsToValue = newRecord.getPopulatedFieldsAsMap();
        for(String field : fieldsToValue.keySet()) {
            if(expression.containsIgnoreCase(field)) {
                // System.debug('PUT :' + field + ' ' + fieldsToValue.get(field));
                newObjMap.put(field, fieldsToValue.get(field));
            }
        }
        // for (String token : expressions) {
        //     if(fieldsToValue.containsKey(token)) {
        //         newObjMap.put(token, fieldsToValue.get(token));
        //     }
        // }
        
        // System.debug(expression);
        // System.debug(newObjMap);
        
        return new RT_Expression(expression, newObjMap);
    }

    public static RT_Expression parseRTExpress(String expression, Map<String, sObject> sobjMap) {
        Map<String, Object> newObjMap = new Map<String, Object>();
        Integer index = 0;
        while(expression.indexOf('newRecord.', index) >= 0) {
            index = expression.indexOf('newRecord.', index);
            String field = expression.substringBetween('newRecord.', ' ');
            newObjMap.put('newRecord.'+field, sobjMap.get('newRecord').get(field));
            index = index + 1;
        }

        while(expression.contains('IsChange')) {
            String field = expression.substringBetween('IsChange(', ')');
            expression = expression.replace('IsChange('+field+')', 'oldRecord.'+field+' != newRecord.'+field);
            newObjMap.put('newRecord.'+field, sobjMap.get('newRecord').get(field));
            newObjMap.put('oldRecord.'+field, sobjMap.get('oldRecord').get(field));
        }
        return new RT_Expression(expression, newObjMap);
    }
}