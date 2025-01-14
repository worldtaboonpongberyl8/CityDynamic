({
    setRecordTypePage: function (component ) {
        const myPageRef = component.get("v.pageReference");
        const recordTypeId = myPageRef.state.recordTypeId;
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            url:
                "/lightning/o/Opportunity/new?count=1&nooverride=1&recordTypeId=" +
                recordTypeId +
                "&defaultFieldValues=Name=Auto+Generate&backgroundContext=%2Flightning%2Fo%2FOpportunity%2Flist?filterName=Recent",
            isredirect: "true"
        });
        urlEvent.fire();
    }
});