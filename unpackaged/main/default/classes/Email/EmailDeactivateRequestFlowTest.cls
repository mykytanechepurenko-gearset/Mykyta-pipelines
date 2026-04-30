@isTest
public class EmailDeactivateRequestFlowTest {
    static final String TEST_EMAIL = 'test@example.com';
    
    static Contact createContact(ID accId) {
        Contact contact = new Contact(
            LastName = 'Test Contact',
            AccountId = accId,
            Email = TEST_EMAIL
        );
        insert contact;

        return contact;
    }
    
    static Lead createLead() {
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Status = 'Interested',
            LeadSource = 'Web',
            Business_Type__c = 'Charity',
            Marketing_Preferences_Checked__c = true,
            Email = TEST_EMAIL
        );
        insert lead;
        
        return lead;
    }
    
    static Account createAccount() {
        Account account = new Account(
            Name = 'Test Account',
            Email_Address__c = TEST_EMAIL // Assuming a custom field Email_Address__c on Account
        );
        insert account;
        
        return account;
    }
 
    @isTest
    static void TestFlowEmailUpdate_WhenTheValidEmailIsProvidedEmailIsUpdated() {
        // Step 1: Create a Lead, Account, and Contact with the same email 
        Lead testLead = createLead();
        Account testAccount = createAccount();
        Contact testContact = createContact(testAccount.Id);
 
        // Step 2: Prepare to invoke the flow
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('Var_Input_AdditionalInformation', 'Test Additional Info');
        inputs.put('Var_Input_Email', TEST_EMAIL);
        inputs.put('Var_Input_ReasonForDeactivating', 'Other');
        inputs.put('Var_Input_SubmitterEmail', 'dayton.meyer@flagstoneim.com');
 
        Flow.Interview.Email_Deactivation_Request_Flow myFlow = new Flow.Interview.Email_Deactivation_Request_Flow(inputs);
        myFlow.start();
 
        system.debug('Flow ran at ' + DateTime.now());
 
        Object foundRecords = myFlow.getVariableValue('Var_Output_FoundRecords');
        Object errorMessage = myFlow.getVariableValue('Var_Output_ErrorMessage');
 
        system.debug('Found Records variable = ' + foundRecords);
        system.debug('Error Message = ' + errorMessage);
 
        // Step 3: Verify the email was updated by the flow
        // Assuming the flow updates the email to 'test@example.com-deactivated'
        String updatedEmail = 'test@example.com-deactivated';
 
        testLead = [SELECT Email FROM Lead WHERE Id = :testLead.Id];
        testAccount = [SELECT Email_Address__c FROM Account WHERE Id = :testAccount.Id];
        testContact = [SELECT Email FROM Contact WHERE Id = :testContact.Id];
 
        System.assertEquals(updatedEmail, testLead.Email, 'Lead email should be updated');
        System.assertEquals(updatedEmail, testAccount.Email_Address__c, 'Account email should be updated');
        System.assertEquals(updatedEmail, testContact.Email, 'Contact email should be updated');
        System.assertEquals(true, (Boolean)foundRecords);
        System.assertEquals(null, errorMessage);
    }
    
    @isTest
    static void TestFlowEmailUpdate_WhenTheValidEmailNotAvailableIsProvided_FoundRecordIsSetToFalse() {
        // Step 1: Create a Lead, Account, and Contact with the same email 
        Lead testLead = createLead();
        Account testAccount = createAccount();
        Contact testContact = createContact(testAccount.Id);
 
        // Step 2: Prepare to invoke the flow
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('Var_Input_AdditionalInformation', 'Test Additional Info');
        inputs.put('Var_Input_Email', 'NotAvailable' + TEST_EMAIL);
        inputs.put('Var_Input_ReasonForDeactivating', 'Other');
        inputs.put('Var_Input_SubmitterEmail', 'dayton.meyer1@flagstoneim.com');
 
        Flow.Interview.Email_Deactivation_Request_Flow myFlow = new Flow.Interview.Email_Deactivation_Request_Flow(inputs);
        myFlow.start();
 
        system.debug('Flow ran at ' + DateTime.now());
 
        Object foundRecords = myFlow.getVariableValue('Var_Output_FoundRecords');
        Object errorMessage = myFlow.getVariableValue('Var_Output_ErrorMessage');
 
        system.debug('Found Records variable = ' + foundRecords);
        system.debug('Error Message = ' + errorMessage);
        
        System.assertEquals(false, (Boolean)foundRecords);
        System.assertEquals(null, errorMessage);
    }
    
    @isTest
    static void TestFlowEmailUpdate_WhenInCompleteDetailsAreProvided_ErrorMessageIsThrown() {
        // Step 1: Create a Lead, Account, and Contact with the same email 
        Lead testLead = createLead();
        Account testAccount = createAccount();
        Contact testContact = createContact(testAccount.Id);
 
        // Step 2: Prepare to invoke the flow
        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('Var_Input_AdditionalInformation', 'Test Additional Info');
        inputs.put('Var_Input_ReasonForDeactivating', '');
        inputs.put('Var_Input_SubmitterEmail', 'dayton.meyer1@flagstoneim.com');
 
        Flow.Interview.Email_Deactivation_Request_Flow myFlow = new Flow.Interview.Email_Deactivation_Request_Flow(inputs);
        myFlow.start();
 
        system.debug('Flow ran at ' + DateTime.now());
 
        Object foundRecords = myFlow.getVariableValue('Var_Output_FoundRecords');
        Object errorMessage = myFlow.getVariableValue('Var_Output_ErrorMessage');
 
        system.debug('Found Records variable = ' + foundRecords);
        system.debug('Error Message = ' + errorMessage);
        
        System.assertEquals(false, String.isBlank((string)errorMessage));
    }
}