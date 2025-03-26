global class PKGUnInstallScript implements UninstallHandler {
    global void onUninstall(UninstallContext ctx) {
        System.debug('Uninstall script is called');
        
        List<PermissionSet> pr = new List<PermissionSet>();
        try{

            Account acc = new Account();
            acc.Name = 'Uninstall Account';
            insert acc;
            // User u = [Select Id, Email from User where Id =:ctx.uninstallerID()];   
            // String toAddress= u.Email;
            // String[] toAddresses = new String[] {toAddress};
            // Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            // mail.setToAddresses(toAddresses);
            // mail.setReplyTo('support@package.dev');
            // mail.setSenderDisplayName('My Package Support');
            // mail.setSubject('Package uninstall successful');
            // mail.setPlainTextBody('Account created');
            // Messaging.sendEmail(new Messaging.Email[] { mail });
            // pr = [SELECT Id,Name FROM PermissionSet WHERE Name = 'Xero_Webhook_Permission_Set_for_Site_User' LIMIT 1];
            // //delete pr;
    
            // if(pr.size() > 0){
            //     List<PermissionSetAssignment> perAssList = new List<PermissionSetAssignment>();
            //     perAssList = [SELECT Id, PermissionSetId FROM PermissionSetAssignment WHERE PermissionSetId =: pr[0].Id];
            //     Boolean flag = false;
            //     Boolean successFlag = false;
    
            //     if(perAssList.size() > 0){
            //         Database.DeleteResult[] drList = Database.delete(perAssList, false);
            //         // Iterate through each returned result
            //         for(Database.DeleteResult dr : drList) {
            //             if (dr.isSuccess()) {
            //                 flag = true;           
            //             }else {
            //                 flag = false;
            //             }
            //         }
            //         if(flag){
            //             Database.DeleteResult[] delPer = Database.delete(pr, false);
            //             for(Database.DeleteResult dr : delPer) {
            //                 if (dr.isSuccess()) {
            //                     successFlag = true;           
            //                 }else {
            //                     successFlag = false;
            //                 }
            //             }
            //         }
            //     }else{
            //         Database.DeleteResult[] delPer = Database.delete(pr, false);
            //         successFlag = true;
            //     }
            //     System.debug('successFlag=='+successFlag);
               
            // }
        }catch(Exception e){
            System.debug('Error '+e.getLineNumber()+'===='+e.getMessage());
            String query = 'Select Id, Email from User where Id =:ctx.uninstallerID()';
            User u = Database.query(String.escapeSingleQuotes(query));   
            String toAddress= u.Email;
            String[] toAddresses = new String[] {toAddress};
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setReplyTo('support@package.dev');
            mail.setSenderDisplayName('My Package Support');
            mail.setSubject('Package uninstall successful');
            mail.setPlainTextBody('Script is failing. Exception is on Line no: '+e.getLineNumber()+'===='+e.getMessage());
            Messaging.sendEmail(new Messaging.Email[] { mail });
        }

    }
}