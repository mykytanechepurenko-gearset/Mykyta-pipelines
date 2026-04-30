public class OnboardingEmailEventTriggerHandler extends TriggerHandler { 
    private static final Set<String> WHITELABELLED_TEMPLATED_LEADSOURCES = new Set<String> { 'Interactive Investor', 'SJP', 'Smith and Williamson', 'Tilney', 'Saga' };
    @TestVisible private static final String DEFAULT_ORG_WIDE_ADDRESS_DISPLAY_NAME = 'Applications';
            
    private List<OrgWideEmailAddress> orgWideEmails = null;
    private List<OrgWideEmailAddress> orgWideEmailAddress {
        get {
            if (orgWideEmails == null) {
                orgWideEmails = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress];
            }
            return orgWideEmails;
        }
    }

    Map<string, string> emailAddressMap = new Map<string, string> {
        'Interactive Investor' => 'Flagstone Client Services (for Interactive Investor)',
        'Saga' => 'Saga-Do Not Reply'
    };

    @TestVisible static Integer TotalSentEmails = 0;
        
    public override void afterInsert() {
        string defaultEmailAddressId = matchEmailAddress(DEFAULT_ORG_WIDE_ADDRESS_DISPLAY_NAME);
        if(defaultEmailAddressId == null) {
            throw new OnboardingEmailException('Default Org-Wide email address named Applications not found');
        }

        handleOnboardingEmailEvent();
    }
        
    public static OrgWideEmailAddress GetDefaultOrgWideApplicationsEmailAddress() {
        OrgWideEmailAddress[] orgWideAddresses = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE DisplayName=:DEFAULT_ORG_WIDE_ADDRESS_DISPLAY_NAME OR Address Like :DEFAULT_ORG_WIDE_ADDRESS_DISPLAY_NAME]; 
        if(orgWideAddresses.size() <= 0) {
            throw new OnboardingEmailException('Default Org-Wide email address named Applications not found');
        }
        return orgWideAddresses.get(0);
    }
    
    private void handleOnboardingEmailEvent() {   
        List<OnboardingEmail_Event__e> newEmailEventList = (List<OnboardingEmail_Event__e>) trigger.New;
        Set<Id> oppIds = new Set<Id>();
        
        for (OnboardingEmail_Event__e event : newEmailEventList) {
            System.debug('Email send initiated for Opportunity Id: ' + event.Opportunity_ID__c);
            oppIds.add(event.Opportunity_ID__c);
        }
        
        Map<Id, Opportunity> all_opportunities = new Map<Id, Opportunity>([SELECT Name,
                        V3_Onboarding__c,
                        LeadSource,
                        Business_Type__c,
                        StageName,
                        Partner_Contact__c,
						Partner_Contact__r.Id,
						Partner_Contact__r.Email,
                        Client_Email__c,
                        Account_Holder__r.Id, 
                        Account_Holder__r.Conversion_Account_Type__c, 
                        Account_Holder__r.Marketing_Opted_In__c, 
                        Account_Holder__r.Partner_Contact__c,
						Primary_Account_Holder_Document_Link__c
                    FROM Opportunity WHERE Id =: oppIds]);

        Onboarding_Email_Settings__mdt obEmailSettings = [SELECT Snippet_Whitelabels__c from Onboarding_Email_Settings__mdt WHERE QualifiedApiName = 'V3_Email_Settings' LIMIT 1];

        if(!String.isBlank(obEmailSettings.Snippet_Whitelabels__c)){
            Map<Id, Opportunity> whitelabel_opportunities = new Map<Id, Opportunity>();
            Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>();
            
            List<OnboardingEmail_Event__e> whitelabel_events = new List<OnboardingEmail_Event__e>();
            List<OnboardingEmail_Event__e> events = new List<OnboardingEmail_Event__e>();

            String[] whitelabels = obEmailSettings.Snippet_Whitelabels__c.split(',');

            for (OnboardingEmail_Event__e ev : newEmailEventList){
                Opportunity op = all_opportunities.get(ev.Opportunity_ID__c);

                if( whitelabels.contains(op.LeadSource))
                {
                    whitelabel_events.add( ev );
                    whitelabel_opportunities.put(op.Id, op);
                }
                else
                {
                    events.add( ev );
                    opportunities.put(op.Id, op);
                }
            }
            
            SnippetEmailer se = new SnippetEmailer();
            se.Send(whitelabel_opportunities, whitelabel_events);
            
            Map<OnboardingEmail_Event__e, EmailTemplate> eventTemplateMap = mapEventWithEmailTemplate(opportunities, events);
            sendEmailMessages(eventTemplateMap, opportunities, events);
        } else {
            Map<OnboardingEmail_Event__e, EmailTemplate> eventTemplateMap = mapEventWithEmailTemplate(all_opportunities, newEmailEventList);
            sendEmailMessages(eventTemplateMap, all_opportunities, newEmailEventList);
        }
        
    }
    
    private Map<OnboardingEmail_Event__e, EmailTemplate> mapEventWithEmailTemplate(Map<Id, Opportunity> opportunities, List<OnboardingEmail_Event__e> events) {
        Map<OnboardingEmail_Event__e, string> eventTemplateNameMap = new Map<OnboardingEmail_Event__e, string>();
        for (OnboardingEmail_Event__e event : events) {
            Opportunity opportunity = opportunities.get(event.Opportunity_ID__c);
        	System.debug('Email send initiated for Opportunity with stage: ' + opportunity.StageName);
            string templateNameClause = '%' + ForCdpVersion(opportunity)
                						+ withLeadsource(opportunity)
                						+ withStageName(opportunity)
                						+ withReferredOrDirect(opportunity)
                						+ forClientOrAdviser(event)
                						+ forApplicant(event) 
                						+ withExtras(event) + '%';
            System.debug('Email template clause: ' + templateNameClause);
            eventTemplateNameMap.put(event, templateNameClause);
        }

        List<EmailTemplate> templates = [SELECT Id, Name, DeveloperName, Subject, FolderName, Description 
                                         FROM EmailTemplate 
                                         WHERE IsActive = TRUE AND (DeveloperName LIKE :eventTemplateNameMap.values() OR  Description LIKE :eventTemplateNameMap.values()) 
                                         	AND (NOT DeveloperName like '%Snippet%')];
        
        Map<OnboardingEmail_Event__e, EmailTemplate> eventTemplateMap = new Map<OnboardingEmail_Event__e, EmailTemplate>();
        for (OnboardingEmail_Event__e event : eventTemplateNameMap.keySet()) {
            for(EmailTemplate template : templates) {
                System.debug('Found template : ' + template.DeveloperName + ' ' + eventTemplateNameMap.get(event).replace('%', ''));
                if(template.DeveloperName.endsWithIgnoreCase(eventTemplateNameMap.get(event).replace('%', ''))) {
                    System.debug('Matched template : ' + template.DeveloperName + ' for ' + event.EventUuid + ' ' + event.Email_Send_Type__c);
                    eventTemplateMap.put(event, template);
                    continue;
                }
                //workaround for Bug https://dev.azure.com/flagstoneim/Flagstone/_workitems/edit/77641 - use description for longer template names
                if(string.isNotBlank(template.Description) && template.Description.endsWithIgnoreCase(eventTemplateNameMap.get(event).replace('%', ''))) { 
                    eventTemplateMap.put(event, template);
                    continue;
                }
            }
        }
        
        return eventTemplateMap;
    }
    
    private void sendEmailMessages(Map<OnboardingEmail_Event__e, EmailTemplate> eventTemplateMap, Map<Id, Opportunity> opportunities, List<OnboardingEmail_Event__e> events) { 
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        
        for (OnboardingEmail_Event__e event : events) {
            Opportunity opportunity = opportunities.get(event.Opportunity_ID__c);
            EmailTemplate template = eventTemplateMap.get(event);
            
            System.debug('Checking template matched. {Event} - ' + event.EventUuid + ' ' + event.Email_Send_Type__c);
            if(template == null) {
                System.debug('Possible missing template OR the feature email is not required. {Opportunity} - ' + event.Opportunity_ID__c);
                continue;
            }
            
            // Get Email address based on partner or default
            string emailAddressDisplayName = EmailAddressMap.containsKey(opportunity.LeadSource) ? EmailAddressMap.get(opportunity.LeadSource) : DEFAULT_ORG_WIDE_ADDRESS_DISPLAY_NAME;
            string emailAddressId = matchEmailAddress(emailAddressDisplayName);

            //send email
            @TestVisible Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(template.Id);
            mail.setToAddresses(new String[] { event.ForClient__c ? opportunity.Client_Email__c : opportunity.Partner_Contact__r.Email });
            mail.setTargetObjectId(event.ForClient__c ? opportunity.Account_Holder__r.Id : opportunity.Partner_Contact__r.Id);
            mail.setTreatTargetObjectAsRecipient(false);
            mail.setWhatId(opportunity.Id); //important to get the merge fields populated in template field placeholders
            mail.setSaveAsActivity(false);            
            mail.setOrgWideEmailAddressId(emailAddressId);
            
            emailMessages.add(mail);
        }
        
        System.debug('Total emails to send: ' + emailMessages.size());
        TotalSentEmails += emailMessages.size();
        Messaging.SendEmailResult[] results = Messaging.sendEmail(emailMessages);
        for(Messaging.SendEmailResult result : results) {
            if (!result.success) {
                System.debug('The email failed to send: ' + result.errors[0].message);
            }
        }
    }
    
    private string matchEmailAddress(string displayName) {
        string matchingEmailAddressId = null;
        for(OrgWideEmailAddress email : orgWideEmailAddress) {
            if (email.DisplayName == displayName) {
                matchingEmailAddressId = email.Id;
                break;
            }
        }

        return matchingEmailAddressId;
    }

    private string withLeadsource(Opportunity opportunity) {
        return '_' + (WHITELABELLED_TEMPLATED_LEADSOURCES.contains(opportunity.Leadsource) 
                      ? opportunity.Leadsource.replace(' ', '').replace('-', '') : 'FIM');
    }
    
    private string ForCdpVersion(Opportunity opportunity) {
        return opportunity.V3_Onboarding__c ? '_V3' : '_V1';
    }
    
    private string withStageName(Opportunity opportunity) {
        return '_' + opportunity.StageName.replace(' ', '').replace('-', '');
    }
    
    private string withReferredOrDirect(Opportunity opportunity) {
        return opportunity.Partner_Contact__c == null ? '_Direct' : '_Referred';
    }
    
    private string forClientOrAdviser(OnboardingEmail_Event__e event) {
        return event.ForClient__c ? '_Client' : '_Adviser';
    }
    
    private string forApplicant(OnboardingEmail_Event__e event) {
        return event.ForPrimaryApplicant__c ? '_Primary' : '_Secondary';
    }
    
    private string withExtras(OnboardingEmail_Event__e event) {
        return event.PartnerOnBehalfOfCustomer__c ? '_BehalfOf' : '';
    }
    
    public class OnboardingEmailException extends Exception {}
}