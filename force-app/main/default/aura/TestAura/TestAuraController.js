({"doInIt": function doInit (component,helper) {

    var opportunityId = component.get("v.recordId");
    if (!opportunityId) {
        opportunityId = helper.getUrlParameter('c__opportunityId');
        // Handle if opportunityId is still not found
    }
    
    document.addEventListener(
        "aura://refreshView",
        ($A) => {

            $A.get("e.force:refreshView").fire();

        }
    );
	
}});