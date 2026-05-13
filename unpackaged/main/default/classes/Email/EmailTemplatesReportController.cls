public without sharing class EmailTemplatesReportController {
	public List<EmailTemplate> templates { get; set; }
	public EmailTemplatesReportController() {
		// Query the emailtemplates
		this.templates = [
			SELECT Id, IsActive, TimesUsed, LastUsedDate, Folder.Name, Name, CreatedBy.Name, LastModifiedBy.Name, CreatedDate, LastModifiedDate
			FROM EmailTemplate
			ORDER BY LastUsedDate DESC NULLS LAST, LastModifiedDate DESC NULLS LAST, TimesUsed DESC NULLS LAST, isActive DESC, Name ASC
		];
	}
}