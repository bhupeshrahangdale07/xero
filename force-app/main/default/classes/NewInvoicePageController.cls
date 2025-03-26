/**
     * @description Class which is intermediator to override New Invoice button in related list of Opportunity
     * @Author : Kandisa Technologies
     * @CreatedDate : 10 Oct 2023
    */
public class NewInvoicePageController {
    /**
     * @description constructor to define standard controller extension
     * @param controller
    */
    public NewInvoicePageController(ApexPages.StandardController controller){}
    
    /**
     * @description Method t fetch Id from the URL and redirect page to LWC component 
     * @return PageReference
     * @param
    */
    public PageReference createInvoice(){
        Map<String, String> params = ApexPages.currentPage().getParameters();
        
        List<string> str = new List<String>();
        if(params.containskey('save_new_url')){
            str = params.get('save_new_url').split('id=');
        }
        
        PageReference pr;
        if(str.size() > 0){
            pr = new PageReference('/lightning/n/KTXero__New_Inv/#/?type=opportunity&recid='+String.escapeSingleQuotes(str[1]));
            pr.setRedirect(true);
        }        
        return pr;
    }
     
}