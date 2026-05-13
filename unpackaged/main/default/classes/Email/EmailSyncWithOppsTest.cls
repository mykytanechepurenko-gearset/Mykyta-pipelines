@isTest
public class EmailSyncWithOppsTest {
    static Contact createContact(id accId, string email, string lastName) {
        Contact con = new Contact(AccountId=accId, Email=email, LastName=lastName);
        insert con;

        return con;
    }

    static Contact createPartnerContact(id accId, string email, string lastName, string PartnerCode) {
        Contact partnerContact = createContact(accId, email, lastName);
        partnerContact.Partner_Code__c = PartnerCode;

        update partnerContact;
        
        return partnerContact;
    }

    static Contact getContactByLastName(string lastName) {
        return [SELECT Email, AccountId, Conversion_Account_Type__c, FirstName, LastName, Partner_Code__c FROM Contact WHERE LastName = :lastName LIMIT 1];
    }

    static Opportunity getOppByAccHolder(ID primaryConId) {
        return [SELECT Name FROM Opportunity WHERE Account_Holder__c = :primaryConId];
    }

    static Opportunity getOppByName(string Name) {
        return [SELECT Name, Business_Type__c FROM Opportunity WHERE Name = :Name LIMIT 1];
    }

    static Account getAccountById(ID accId) {
        return [SELECT Name FROM Account WHERE Id = :accId];
    }

    static void updateContactNameAndLastName(Contact cont, string name, string lastName){
        cont.FirstName = name;
        cont.LastName = lastName;
        update cont;
    }

    @testSetup static void setup() {
        Account acc = new Account();
        acc.Name = 'AccountTest';
        insert acc;

        Contact primaryCon = createContact(acc.Id, '1@test.com', 'Test');
        Contact secondaryCon = createContact(acc.Id, 'secondary@test.com', 'Test Secondary');
        Contact partnerCon = createPartnerContact(acc.Id, '2@test.com', 'PartnerTest', 'TESTCODE');

        Opportunity opp = new Opportunity(Name = 'Test', AccountId = acc.Id, Business_Type__c='HNW', Account_Holder__c = primaryCon.Id, Secondary_Account_Holder__c = secondaryCon.Id, Partner_Contact__c = partnerCon.Id, CloseDate = date.today(), StageName = 'Qualified');
        insert opp;

        OpportunityContactRole ocrPrimary = new OpportunityContactRole(ContactId = primaryCon.Id, OpportunityId = opp.Id, IsPrimary = true);
        insert ocrPrimary;

        OpportunityContactRole ocrSecondary = new OpportunityContactRole(ContactId = secondaryCon.Id, OpportunityId = opp.Id, IsPrimary = false);
        insert ocrSecondary;
    }

    @isTest 
    static void GivenAnApplicant_WhenContactEmailIsUpdated_ThenOpportunityEmailIsUpdated() {
        //arrange test data
        string newEmail = 'changed@test.com';

        Contact con = getContactByLastName('Test');
        con.Email = newEmail;
        update con;

        // Verify 
        Opportunity oppTest = [SELECT Client_Email__c FROM Opportunity WHERE Account_Holder__c = :con.Id];
        System.assertEquals(newEmail, oppTest.Client_Email__c);
    }

    @isTest 
    static void GivenAnApplicant_WhenPartnerCodeIsUpdated_ThenOpportunityPartnerCodeIsUpdated() {
        //arrange test data
        string newCode = 'CHANGEDCODE';

        Contact con = getContactByLastName('PartnerTest');
        con.Partner_Code__c = newCode;
        update con;

        // Verify 
        Opportunity oppTest = [SELECT Partner_Code__c FROM Opportunity WHERE Partner_Contact__c = :con.Id];
        System.assertEquals(newCode, oppTest.Partner_Code__c);
    }
    
    // CS: FIL Migration
    // @isTest 
    // static void GivenAV3Applicant_WhenPartnerCodeIsUpdated_ThenOpportunityPartnerCodeIsNotUpdated() {
    //     //arrange test data
    //     string newCode = 'CHANGEDCODE';

    //     //act
    //     Contact con = getContactByLastName('PartnerTest');
        
    //     Opportunity oppTest = [SELECT V3_Onboarding__c, Partner_Code__c FROM Opportunity WHERE Partner_Contact__c = :con.Id];
    //     oppTest.V3_Onboarding__c = true;
    //     update oppTest;
        
    //     con.Partner_Code__c = newCode;
    //     update con;

    //     // Verify 
    //     oppTest = [SELECT Partner_Code__c, PartnerCode__c FROM Opportunity WHERE Partner_Contact__c = :con.Id];
    //     System.assertEquals(newCode, oppTest.PartnerCode__c);
    //     System.assertNotEquals(newCode, oppTest.Partner_Code__c);
    // }

    @isTest 
    static void GivenMAJointApplicant_WhenContactNameChangesWithSameLastName_ThenOpportunityAccountNamesAreUpdatedWithAmpersand() {
        //arrange test data
        Opportunity opp = getOppByName('Test');
        opp.Business_Type__c = 'Mass Affluent Joint';
        update opp;

        Contact primaryCon = getContactByLastName('Test');
        updateContactNameAndLastName(primaryCon, 'John', 'Doe');

        Contact secondaryCon = getContactByLastName('Test Secondary');
        updateContactNameAndLastName(secondaryCon, 'Jane', 'Doe');

        string expectedName = 'John & Jane Doe';

        // Verify 
        Opportunity oppTest = getOppByAccHolder(primaryCon.Id);
        System.assertEquals(expectedName, oppTest.Name);

        Account accTest = getAccountById(primaryCon.AccountId);
        System.assertEquals(expectedName, accTest.Name);
    }

    @isTest 
    static void GivenMAJointApplicant_WhenContactNameChanges_ThenOpportunityAccountNamesAreUpdated() {
        //arrange test data
        Opportunity opp = getOppByName('Test');
        opp.Business_Type__c = 'Mass Affluent Joint';
        update opp;

        Contact primaryCon = getContactByLastName('Test');
        updateContactNameAndLastName(primaryCon, 'John', 'Doe');

        Contact secondaryCon = getContactByLastName('Test Secondary');
        updateContactNameAndLastName(secondaryCon, 'Jane', 'Acme');

        string expectedName = 'John Doe & Jane Acme';

        // Verify 
        Opportunity oppTest = getOppByAccHolder(primaryCon.Id);
        System.assertEquals(expectedName, oppTest.Name);

        Account accTest = getAccountById(primaryCon.AccountId);
        System.assertEquals(expectedName, accTest.Name);
    }

    @isTest 
    static void GivenHNWJointApplicant_WhenContactNameChangesWithSameLastName_ThenOpportunityAccountNamesAreUpdatedWithAmpersand() {
        //arrange test data
        Opportunity opp = getOppByName('Test');
        opp.Business_Type__c = 'HNW Joint';
        update opp;

        Contact primaryCon = getContactByLastName('Test');
        updateContactNameAndLastName(primaryCon, 'John', 'Doe');

        Contact secondaryCon = getContactByLastName('Test Secondary');
        updateContactNameAndLastName(secondaryCon, 'Jane', 'Doe');

        string expectedName = 'John & Jane Doe';

        // Verify 
        Opportunity oppTest = getOppByAccHolder(primaryCon.Id);
        System.assertEquals(expectedName, oppTest.Name);

        Account accTest = getAccountById(primaryCon.AccountId);
        System.assertEquals(expectedName, accTest.Name);
    }

    @isTest 
    static void GivenHNWJointApplicant_WhenContactNameChanges_ThenOpportunityAccountNamesAreUpdated() {
        //arrange test data
        Opportunity opp = getOppByName('Test');
        opp.Business_Type__c = 'HNW Joint';
        update opp;

        Contact primaryCon = getContactByLastName('Test');
        updateContactNameAndLastName(primaryCon, 'John', 'Doe');

        Contact secondaryCon = getContactByLastName('Test Secondary');
        updateContactNameAndLastName(secondaryCon, 'Jane', 'Acme');

        string expectedName = 'John Doe & Jane Acme';

        // Verify 
        Opportunity oppTest = getOppByAccHolder(primaryCon.Id);
        System.assertEquals(expectedName, oppTest.Name);

        Account accTest = getAccountById(primaryCon.AccountId);
        System.assertEquals(expectedName, accTest.Name);
    }

    @isTest 
    static void GivenCorporateJointApplicant_WhenContactNameChanges_ThenOpportunityNamesAreNotUpdated() {
        //arrange test data for offline applications not reached Client stage
        string compName = 'Dope Corp';

        Opportunity opp = getOppByName('Test');
        opp.Business_Type__c = 'Corporate';
        opp.Name = compName;
        update opp;

        Contact primaryCon = getContactByLastName('Test');
        primaryCon.Conversion_Account_Type__c = 'Organisations';
        primaryCon.FirstName = 'John';
        primaryCon.LastName = 'Doe';
        update primaryCon;

        Contact secondaryCon = getContactByLastName('Test Secondary');
        updateContactNameAndLastName(secondaryCon, 'Jane', 'Acme');

        Contact primaryCon2 = [SELECT AccountId, FirstName, LastName FROM Contact WHERE Id = :primaryCon.Id];
        primaryCon2.FirstName = 'John';
        primaryCon2.LastName = 'Doe';
        update primaryCon2;

        Contact secondaryCon2 = [SELECT AccountId, FirstName, LastName FROM Contact WHERE Id = :secondaryCon.Id];
        secondaryCon2.FirstName = 'Jane';
        secondaryCon2.LastName = 'Acme';
        update secondaryCon2;


        // Verify
        Opportunity oppTest = getOppByAccHolder(primaryCon.Id);
        System.assertEquals(compName, oppTest.Name);

        Account accTest = getAccountById(primaryCon2.AccountId);
        System.assertEquals(compName, accTest.Name);
    }
}