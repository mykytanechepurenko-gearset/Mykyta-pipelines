@SuppressWarnings('PMD.ExcessiveParameterList,PMD.IfStmtsMustUseBraces,PMD.IfElseStmtsMustUseBraces')
public class OnboardingEmailContext {
    //all possible email types to be added here
    public enum EmailType {
        REFERRAL_CREATED,
            
        APPLIED_RECEIVED_TO_ADVISER,
        APPLIED_RECEIVED_TO_CLIENT, //applicable only for V1
        
        MANUAL_REVIEW_TO_ADVISER,
            
        APPLICANT_PENDING_INFORMATION_TO_ADVISER,
        
        INFORMATION_RECEIVED_TO_ADVISER,
        INFORMATION_RECEIVED_TO_CLIENT, //applicable only for V1
            
        EKYC_APPROVED_TO_CLIENT,
        
        ACCOUNT_OPENED_TO_ADVISER,
            
        ACCOUNT_REJECTED_TO_CLIENT
    }
    public enum ApplicantType { PRIMARY, SECONDARY }
    public enum EmailRecepient { CLIENT, ADVISER }
    
    @TestVisible private static OnboardingEmailContext instance = null;    
    @TestVisible private List<OnboardingEmail_Event__e> obEmailEvents;
    @TestVisible private static IEventBusPublisher obEventBus;
    
    private OnboardingEmailContext() {
        obEmailEvents = new List<OnboardingEmail_Event__e>();
        obEventBus = new EventBusPublisher();
    }
    
    public static OnboardingEmailContext getInstance() {
        // lazy load instance
        if(instance == null) instance = new OnboardingEmailContext();
        return instance;
    }
    
    public void addEmailEvent(EmailType emailType, Id sObjectId) {
        addEmailEvent(emailType, sObjectId, true);
    }
    public void addEmailEvent(EmailType emailType, Id sObjectId, boolean isForClient) {
        addEmailEvent(emailType, sObjectId, isForClient, true);
    }
    public void addEmailEvent(EmailType emailType, Id sObjectId, boolean isForClient, boolean isForPrimaryApplicant) {
        addEmailEvent(emailType, sObjectId, isForClient, isForPrimaryApplicant, false);
    }
    public void addEmailEvent(EmailType emailType, Id sObjectId, boolean isForClient, boolean isForPrimaryApplicant, boolean isPartnerOnBehalfOfCustomer) {
        System.debug('Onboarding Email Context, Existing events size:' + obEmailEvents.size());
        OnboardingEmail_Event__e event = new OnboardingEmail_Event__e (
            Opportunity_ID__c = sObjectId,
        	Email_Send_Type__c = emailType.name(),
            ForClient__c = isForClient,
            ForPrimaryApplicant__c = isForPrimaryApplicant,
            PartnerOnBehalfOfCustomer__c = isPartnerOnBehalfOfCustomer
        );
        if(!hasEmailEvent(event)) {
        	obEmailEvents.add(event);
        }
    }
    
    private boolean hasEmailEvent(OnboardingEmail_Event__e event) {
        for(OnboardingEmail_Event__e existingEvent : obEmailEvents) {
            if(existingEvent.Opportunity_ID__c == event.Opportunity_ID__c &&
        		existingEvent.Email_Send_Type__c == event.Email_Send_Type__c &&
                existingEvent.ForClient__c == event.ForClient__c &&
                existingEvent.ForPrimaryApplicant__c == event.ForPrimaryApplicant__c &&
                existingEvent.PartnerOnBehalfOfCustomer__c == event.PartnerOnBehalfOfCustomer__c) {
                   return true;
               }
        }
        return false;
    }
    
    public void raiseEmailEvents() {
        System.debug(string.format('Onboarding Email Context, publishing email events [{0}]', new object[] { obEmailEvents.size() }));
        if(obEmailEvents.size() <= 0) {
            return;
        }
        boolean success = true;
        List<Database.SaveResult> results = obEventBus.publish(obEmailEvents);
        // CS: The event bus publisher outputs results to debug log, only have to check for success
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess() == false) {
                success = false;
                break;
            }
        }
        if(success) {
            obEmailEvents.clear();
        }
    }
}