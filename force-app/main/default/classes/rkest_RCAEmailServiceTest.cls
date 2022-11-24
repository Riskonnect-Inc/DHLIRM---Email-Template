@isTest
private class rkest_RCAEmailServiceTest {
    static testMethod void test_EmailService() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        Messaging.InboundEmailResult res = new rkes_RCAEmailService().handleInboundEmail(email, envelope);
    }
}