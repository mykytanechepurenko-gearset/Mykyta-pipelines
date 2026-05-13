@isTest 
public class OnboardingEmailEventTriggerHandlerTest {
	@isTest
    public static void GivenOnboardingEmailEvent_WhenReceived_OrgWideEmailAddressDefaultsToApplications() {
        OrgWideEmailAddress address = OnboardingEmailEventTriggerHandler.GetDefaultOrgWideApplicationsEmailAddress();
        
        System.assert(address != null, 'No default org-wide address set');        
        System.assertEquals(OnboardingEmailEventTriggerHandler.DEFAULT_ORG_WIDE_ADDRESS_DISPLAY_NAME, address.DisplayName, 'Applications should be default org-wide email address');
    }
}