public class MockHttpResponseGenerator implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        // Create mock HTTP response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"records":[{"TableEnumOrId":"Opportunity","Name":"Layout1"},{"TableEnumOrId":"Opportunity","Name":"Layout2"}]}');
        res.setStatusCode(200);
        return res;
    }
}