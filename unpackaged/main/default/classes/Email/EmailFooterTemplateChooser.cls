global class EmailFooterTemplateChooser implements Support.EmailTemplateSelector {
    public EmailFooterTemplateChooser() {  }

    global ID getDefaultEmailTemplateId(ID caseId) {
        Case caseObj = [SELECT ContactId, Contact.LeadSource, RecordType.DeveloperName FROM Case WHERE Id=:caseId];

        System.debug('Feed Case: ' + caseObj.Contact.LeadSource + ' ' + caseObj.Id);

        List<EmailTemplate> emailSignatureTemplates = 
            [SELECT id, Name, DeveloperName, FolderName FROM EmailTemplate WHERE Folder.Name like 'Email Signatures' AND IsActive=true];

        for (EmailTemplate emailSignatureTemplate : emailSignatureTemplates) {
            System.debug(LoggingLevel.DEBUG, 'Template : ' + emailSignatureTemplate.DeveloperName);
            System.debug(LoggingLevel.DEBUG, 'contact id : ' + caseObj.ContactId);
            System.debug(LoggingLevel.DEBUG, 'Leadsource of contact : ' + caseObj.Contact.LeadSource.replace(' ', '').replace('-', ''));    
            if(caseObj.ContactId != null && 
                String.isNotBlank(caseObj.Contact.LeadSource) &&
                emailSignatureTemplate.DeveloperName.startsWith(caseObj.Contact.LeadSource.replace(' ', '').replace('-', ''))) {
                    return emailSignatureTemplate.Id;
                }
        }
        
        for (EmailTemplate emailSignatureTemplate : emailSignatureTemplates) {
            if(emailSignatureTemplate.DeveloperName.startsWith('Default')) {
                    return emailSignatureTemplate.Id;
                }
        }

        return null;
    }
}