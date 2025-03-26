public class WebServiceMockImpl implements WebServiceMock {
	public void doInvoke(
		Object stub, Object request, Map<String, Object> response,
		String endpoint, String soapAction, String requestName,
		String responseNS, String responseName, String responseType) {

		// test for the type of the response, OP was just doing readMetaData()
		if(request instanceof MetadataService.readMetadata_element){
			MetadataService.readMetadata_element requestReadMetadata_element  = 
					(MetadataService.readMetadata_element) request;
			// This allows you to generalize the mock response by type of metadata read
			if (requestReadMetadata_element.type_x == 'Layout') { 
				MetadataService.readLayoutResponse_element mockRes   = 
					new MetadataService.readLayoutResponse_element();
				mockRes.result = new MetaDataService.ReadLayoutResult();
				mockRes.result.records = createLayout();

				
				response.put('response_x', mockRes);
			}
			
		}
		else if (request instanceof MetadataService.updateMetadata_element) {
			// mock the updateMetadata() response 
		}
		// else if (...) any other response you have to mock
		return;
	}

	private static MetadataService.Layout[] createLayout(){
		MetadataService.Layout[] objects = new MetadataService.Layout[]{};

		MetadataService.Layout obj = new MetadataService.Layout();
		obj.fullName = 'Opportunity Layout';
		obj.type = 'Layout';
		obj.relatedLists = createRelatedList();
		objects.add(obj);

		MetadataService.Layout obj2 = new MetadataService.Layout();
		obj2.fullName = 'Layout1';
		obj.type = 'Layout';
		obj.relatedLists = createRelatedList();
		objects.add(obj2);

		MetadataService.Layout obj3 = new MetadataService.Layout();
		obj3.fullName = 'Layout2';
		obj.relatedLists = createRelatedList();
		objects.add(obj3);

		return objects;

	}

	private static MetadataService.RelatedListItem[] createRelatedList(){
		List<MetadataService.RelatedListItem> objects = new List<MetadataService.RelatedListItem>();
		MetadataService.RelatedListItem obj = new MetadataService.RelatedListItem();
		obj.relatedList = 'KTXero__Invoice__c.KTXero__Opportunity__c';
		objects.add(obj);
		return objects;
	}
}