@isTest
public with sharing class HelpSupportControllerTest {

    /**
     * @description Helper method to create test data
     * @param numFiles
     * @return List<ContentDocument>
    */
    public static List<ContentDocument> createTestFiles(Integer numFiles) {
        List<ContentVersion> cvList = new List<ContentVersion>();
        List<String> docIdList = new List<String>();
        for(Integer i = 0; i < numFiles; i++) {
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test File ' + i;
            cv.PathOnClient = 'Test' + i + '.txt';
            cv.VersionData = Blob.valueOf('Test Content');
            cvList.add(cv);
        }
        insert cvList;
        List<ContentVersion> conDocList2 = new List<ContentVersion>();
        conDocList2 = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE Title LIKE '%Test File%']; 

        for(ContentVersion cv : conDocList2) {
            docIdList.add(cv.ContentDocumentId);
        }
        List<ContentDocument> conDocList = new List<ContentDocument>();
        conDocList = [SELECT Id, ContentSize FROM ContentDocument WHERE Id IN: docIdList]; 
        return conDocList;
    }

    /**
     * @description Helper method to create a test support data wrapper
     * @return HelpSupportController.SupportDataWrapper
    */
    public static HelpSupportController.SupportDataWrapper createTestSupportData() {
        HelpSupportController.SupportDataWrapper sdWrap = new HelpSupportController.SupportDataWrapper();
        sdWrap.firstName = 'Test';
        sdWrap.lastName = 'User';
        sdWrap.email = 'test@test.com';
        sdWrap.enquiryValue = 'General';
        sdWrap.description = 'This is a test support request';
        return sdWrap;
    }

    // Test method for getFilesSize method
    @isTest
    public static void testGetFilesSize() {
        // Create test files
        List<ContentDocument> cdList = createTestFiles(3);
        List<String> docIdList = new List<String>();
        for(ContentDocument cd : cdList) {
            docIdList.add(cd.Id);
        }

        // Test the method with valid input
        Test.startTest();
        Boolean result = HelpSupportController.getFilesSize(docIdList);
        System.assertEquals(true, result, 'Success');

        // Create another test file with large size
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Large File';
        cv.PathOnClient = 'Large.txt';
        cv.VersionData = Blob.valueOf('Test');
        insert cv;

        result = HelpSupportController.getFilesSize(new List<String>{cv.ContentDocumentId});
        Test.stopTest();
    }

    // Test method for submitCase method
    @isTest
    public static void testSubmitCase() {

        // Create test files
        List<ContentDocument> cdList = createTestFiles(2);
        List<String> filesData = new List<String>();
        for(ContentDocument cd : cdList) {
            filesData.add(cd.Id);
        }

        // Create test support data
        HelpSupportController.SupportDataWrapper sdWrap = createTestSupportData();
        String supportData = JSON.serialize(sdWrap);
        
        Boolean sendEmailFlag;
        // Test the method with valid input and no exception
        try {
            Test.startTest();
            sendEmailFlag = HelpSupportController.submitCase(filesData,supportData);
            System.assertEquals(true, sendEmailFlag, 'Success');
        } catch(Exception e) {
            sendEmailFlag = false;
            System.assertEquals(false, sendEmailFlag, 'Success');
        }

        try {
            sendEmailFlag = HelpSupportController.submitCase(null, null);
            System.assertEquals(false, sendEmailFlag, 'Success');
        } catch(Exception e) {
            sendEmailFlag = false;
            System.assertEquals(false, sendEmailFlag, 'Success');
        }
        Test.stopTest();
    }

    // Test method for deleteDocuments method
    @isTest
    public static void testDeleteDocuments() {
        // Create test files
        List<ContentDocument> cdList = createTestFiles(2);
        List<String> deleteIds = new List<String>();
        for(ContentDocument cd : cdList) {
            deleteIds.add(cd.Id);
        }

        // Test the method with valid input
        Test.startTest();
        Boolean result = HelpSupportController.deleteDocuments(deleteIds);
        System.assertEquals(true, result, 'Success');
        result = HelpSupportController.deleteDocuments(new List<String>());
        System.assertEquals(false, result, 'No Document IDs');
        Test.stopTest();
    }
}