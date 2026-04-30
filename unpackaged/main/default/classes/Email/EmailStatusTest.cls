@isTest
public class EmailStatusTest {
    static testMethod void StatusTest(){
        // Create test account
        Account newAcc = new Account(
            Name = 'testAccount'
        );
        insert newAcc;
        
        // Create test contact
        Contact newContact = new Contact(
            FirstName = 'Test',
            LastName = 'Test',
            Email = 'test@test.com',
            AccountId = newAcc.Id
        );
        insert newContact;
        // Create case with Email_Status__c set to "Awaiting response from client"
        Case newCase = new Case(
            Email_Status__c = 'Client responded',
            ContactId = newContact.Id,
            Type = 'Other',
            Origin = 'Other',
            Status = 'New',
            RecordTypeId = surveyResponseRecordTypeId()
        );
        insert newCase;
        EmailMessage em = new EmailMessage(
            Incoming = true,
            FromAddress = 'test@test.com',
            HtmlBody = 'test',
            ParentId = newCase.Id
        );
        insert em;
        newCase = [SELECT Id, Email_Status__c FROM Case WHERE Id = :newCase.Id];
        System.assertEquals(newCase.Email_Status__c, 'Client responded');
    }

    private static String surveyResponseRecordTypeId() {
        return Schema.SObjectType.Case.getRecordTypeInfosByName().get('Survey Response').getRecordTypeId();
    }
}