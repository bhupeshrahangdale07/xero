/**
    @Author : Kandisa Technologies
    @description : Class to fetch success or failure message after authentication process with Xero
    @CreatedDate : 09 Mar 2023
*/
public with sharing class AuthorizationMessageController {
    /**
     * @description Holds the message coming from Parameter
    */ 
    public String message {get;set;}

    /**
     * @description Holds the status of authentication
    */  
    public String val {get;set;}

    /**
     * @description Constrctor to call the pageLoad method
    */
    public AuthorizationMessageController() {
        pageLoad();
    }


    /**
     * @description method to fetch the value on page load 
    */
    public void pageLoad(){
        val = ApexPages.currentPage().getParameters().get('Success').escapeHtml4();
        if(val == 'True'){
            message = 'The authentication process was completed successfully !! You can close this tab now.';
        }else{
            message = 'The authentication process was Failed !! Please try again or contact support.';
        }
    }
}