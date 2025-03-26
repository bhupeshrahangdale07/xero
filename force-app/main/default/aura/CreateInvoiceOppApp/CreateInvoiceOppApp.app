<!--<aura:application extends="ltng:outApp" >
	<c:TestAura />
</aura:application>-->


<aura:application extends="force:slds" implements="force:appHostable,flexipage:availableForAllPageTypes,flexipage:availableForRecordHome,force:hasRecordId,forceCommunity:availableForAllPageTypes,force:hasSObjectName" access="global">
    <aura:attribute name="recordId" type="String"/>    
    <c:TestAura recordId="{!v.recordId}"/>
</aura:application>