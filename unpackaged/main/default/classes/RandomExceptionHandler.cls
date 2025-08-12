public with sharing class RandomExceptionHandler {
    @InvocableMethod(label='Invoke Random Exception' description='Throws a random exception for testing purposes.')
    public static void invokeRandomException() {
        // List of random error messages
        List<String> errorMessages = new List<String>{
            'An unexpected error occurred.',
            'Read timed out',
            'Critical failure during processing.',
            'Data validation error encountered.',
            'The flow tried to update these records: 006N200000M8dIrIAJ.'
        };
        
        // Get a random message from the list
        String randomMessage = errorMessages[Math.mod((Integer)(Math.random() * 100), errorMessages.size())];
        
        // Get a random exception index
        Integer randomExceptionIndex = (Integer)(Math.random() * 5);
        
        switch on randomExceptionIndex {
            when 0 {
                throw new DmlException(randomMessage);
            }
            when 1 {
                throw new CalloutException(randomMessage);
            }
            when 2 {
                throw new FlowException(randomMessage);
            }
            when 3 {
                throw new QueryException(randomMessage);
            }
            when 4 {
                throw new IllegalArgumentException(randomMessage);
            }
            when else {
                throw new NullPointerException();
            }
        }
    }
}