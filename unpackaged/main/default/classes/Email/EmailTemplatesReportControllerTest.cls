@IsTest
public with sharing class EmailTemplatesReportControllerTest {
	@IsTest
	static void testEmailTemplatesReportController() {
		Test.startTest();
		EmailTemplatesReportController controller = new EmailTemplatesReportController();
		Test.stopTest();
		System.assert(controller.templates != null, 'The template collection was not intialized');
	}
}