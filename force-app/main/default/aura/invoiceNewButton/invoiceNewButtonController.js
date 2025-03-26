({
    onPageReferenceChanged: function() {
        $A.get('e.force:refreshView').fire();
    },
    doInit: function (component) {
        const ref = component.get("v.pageReference");
        component.set("v.recordId", ref.state.recid);
	}
});